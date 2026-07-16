[CmdletBinding()]
param(
    [string]$TargetPath = '.',
    [string]$Owner = '',
    [string]$RepositoryName = '',
    [ValidateSet('private', 'public', 'internal')]
    [string]$Visibility = 'private',
    [string]$ProtocolRepository = 'hasanmanzak/meAndAI',
    [string]$ProtocolTag = 'v0.9.0',
    [string]$RemoteName = 'origin',
    [ValidateRange(1, 60)]
    [int]$WorkflowTimeoutMinutes = 15,
    [ValidateRange(1, 120)]
    [int]$CodexTimeoutMinutes = 30,
    [ValidateRange(0, 7200)]
    [int]$CodexTimeoutSeconds = 0,
    [switch]$SkipLifecycleDispatch,
    [Alias('SkipCodexDelegation')]
    [switch]$SkipLocalCodex,
    [string]$CodexCommand = '',
    [string]$TemporaryCodexVersion = '0.144.4'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$workflowSourcePath = 'templates/project/.github/workflows/meandai-protocol-update.yml'
$workflowTargetPath = '.github/workflows/meandai-protocol-update.yml'
$adoptionManifestPath = '.ai/adoption/meandai-capabilities.json'
$adoptionAssets = @(
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
$adoptionUpdaterAssets = @($adoptionAssets | Where-Object {
    [string]$_.ConsumerPath -cin @(
        '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
        '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
    )
})
$secretLockLabel = 'meandai:secret-reconciliation-lock'
$tokenMappings = [ordered]@{
    'FG_PAT.txt' = 'MEANDAI_UPDATER_TOKEN'
    'MEANDAI_RO_FG_PAT.txt' = 'MEANDAI_PROTOCOL_TOKEN'
}
$adoptionLabels = @(
    [pscustomobject]@{ Name = 'type:epic'; Color = '5319e7'; Description = 'Agile epic' },
    [pscustomobject]@{ Name = 'type:feature'; Color = '1d76db'; Description = 'User-facing feature' },
    [pscustomobject]@{ Name = 'type:subfeature'; Color = '0e8a16'; Description = 'Independently testable feature slice' },
    [pscustomobject]@{ Name = 'type:task'; Color = 'd4c5f9'; Description = 'Implementation or maintenance task' },
    [pscustomobject]@{ Name = 'type:bug'; Color = 'd73a4a'; Description = 'Defect' },
    [pscustomobject]@{ Name = 'type:finding'; Color = 'fbca04'; Description = 'Review or scan finding' },
    [pscustomobject]@{ Name = 'priority:p0'; Color = 'b60205'; Description = 'Critical priority' },
    [pscustomobject]@{ Name = 'priority:p1'; Color = 'd93f0b'; Description = 'High priority' },
    [pscustomobject]@{ Name = 'priority:p2'; Color = 'fbca04'; Description = 'Normal priority' },
    [pscustomobject]@{ Name = 'priority:p3'; Color = '0e8a16'; Description = 'Low priority' },
    [pscustomobject]@{ Name = 'status:blocked'; Color = 'b60205'; Description = 'Blocked by an unresolved dependency' },
    [pscustomobject]@{ Name = 'status:in-progress'; Color = '1d76db'; Description = 'Implementation in progress' },
    [pscustomobject]@{ Name = 'status:needs-review'; Color = '5319e7'; Description = 'Ready for maintainer review' }
)

function Invoke-External {
    param(
        [Parameter(Mandatory)][string]$Command,
        [string[]]$Arguments = @(),
        [AllowNull()][string]$InputText = $null,
        [switch]$AllowFailure
    )

    $previousPreference = $ErrorActionPreference
    $previousGitHubHost = [Environment]::GetEnvironmentVariable('GH_HOST', 'Process')
    $ErrorActionPreference = 'Continue'
    try {
        if ($Command -ceq 'gh') {
            [Environment]::SetEnvironmentVariable('GH_HOST', 'github.com', 'Process')
        }
        $global:LASTEXITCODE = 0
        $output = if ($PSBoundParameters.ContainsKey('InputText')) {
            @($InputText | & $Command @Arguments 2>&1)
        }
        else {
            @(& $Command @Arguments 2>&1)
        }
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) {
            $exitCode = 0
        }
    }
    finally {
        if ($Command -ceq 'gh') {
            [Environment]::SetEnvironmentVariable(
                'GH_HOST', $previousGitHubHost, 'Process'
            )
        }
        $ErrorActionPreference = $previousPreference
    }

    if ($exitCode -ne 0 -and -not $AllowFailure) {
        $detail = (@($output) -join [Environment]::NewLine).Trim()
        if ($detail) {
            throw "$Command failed with exit code ${exitCode}: $detail"
        }
        throw "$Command failed with exit code $exitCode."
    }

    return [pscustomobject]@{
        ExitCode = [int]$exitCode
        Output = @($output)
    }
}

function Invoke-Git {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    $allArguments = @('-C', $Repository) + $Arguments
    return Invoke-External -Command 'git' -Arguments $allArguments -AllowFailure:$AllowFailure
}

function Get-NormalizedPath {
    param([Parameter(Mandatory)][string]$Path)

    return [IO.Path]::GetFullPath($Path).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
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

function Get-GitBlobSha {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $header = [Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
    $payload = [byte[]]::new($header.Length + $Bytes.Length)
    [Array]::Copy($header, 0, $payload, 0, $header.Length)
    [Array]::Copy($Bytes, 0, $payload, $header.Length, $Bytes.Length)
    $sha = [Security.Cryptography.SHA1]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($payload))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Test-ByteArrayEqual {
    param(
        [Parameter(Mandatory)][byte[]]$Left,
        [Parameter(Mandatory)][byte[]]$Right
    )

    if ($Left.Length -ne $Right.Length) {
        return $false
    }
    for ($index = 0; $index -lt $Left.Length; $index++) {
        if ($Left[$index] -ne $Right[$index]) {
            return $false
        }
    }
    return $true
}

function Get-AdoptionTreeEntry {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Path,
        [string]$Commit = '',
        [switch]$UseIndex
    )

    if ($UseIndex -eq [bool]$Commit) {
        throw 'Exactly one adoption tree source must be selected.'
    }
    $result = if ($UseIndex) {
        Invoke-Git -Repository $Repository -Arguments @('ls-files', '--stage', '--', $Path)
    }
    else {
        Invoke-Git -Repository $Repository -Arguments @('ls-tree', $Commit, '--', $Path)
    }
    $lines = @($result.Output | Where-Object { $_ })
    $empty = [pscustomobject]@{ Mode = ''; Type = ''; Sha = ''; Path = '' }
    if ($lines.Count -ne 1) {
        return $empty
    }
    $pattern = if ($UseIndex) {
        '^(?<mode>[0-9]{6})\s+(?<sha>[0-9a-f]{40})\s+0\t(?<path>.+)$'
    }
    else {
        '^(?<mode>[0-9]{6})\s+(?<type>[^\s]+)\s+(?<sha>[0-9a-f]{40})\t(?<path>.+)$'
    }
    $match = [regex]::Match([string]$lines[0], $pattern)
    if (-not $match.Success -or [string]$match.Groups['path'].Value -cne $Path) {
        return $empty
    }
    return [pscustomobject]@{
        Mode = [string]$match.Groups['mode'].Value
        Type = if ($UseIndex) { 'blob' } else { [string]$match.Groups['type'].Value }
        Sha = [string]$match.Groups['sha'].Value
        Path = [string]$match.Groups['path'].Value
    }
}

function Get-SingleCommitParent {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Commit
    )

    $line = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'rev-list', '--parents', '-n', '1', $Commit
    )).Output -join '').Trim())
    $parts = @($line -split ' ' | Where-Object { $_ })
    if ($parts.Count -ne 2 -or $parts[0] -cne $Commit -or
        $parts[1] -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The adoption proposal must contain one exact parent commit.'
    }
    return $parts[1]
}

function Get-ExpectedAdoptionManifestContract {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$ProposalHead,
        [Parameter(Mandatory)][string[]]$TargetPaths
    )

    $baseHead = Get-SingleCommitParent -Repository $Repository -Commit $ProposalHead
    $basePaths = @((Invoke-Git -Repository $Repository -Arguments @(
        'ls-tree', '-r', '--name-only', $baseHead
    )).Output | ForEach-Object { [string]$_ })
    $pathLookup = [System.Collections.Generic.Dictionary[string, string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($path in $basePaths) {
        if ([string]::IsNullOrWhiteSpace($path) -or $pathLookup.ContainsKey($path)) {
            throw "The adoption proposal parent contains an empty or case-ambiguous path '$path'."
        }
        $pathLookup.Add($path, $path)
    }
    if ($pathLookup.ContainsKey($adoptionManifestPath)) {
        throw 'The adoption proposal parent already contains the transient adoption manifest.'
    }

    $collisions = [System.Collections.Generic.List[string]]::new()
    foreach ($path in $TargetPaths) {
        if ($pathLookup.ContainsKey($path)) {
            $collisions.Add([string]$pathLookup[$path])
        }
    }
    $updaterCount = @($adoptionUpdaterAssets | Where-Object {
        $pathLookup.ContainsKey([string]$_.ConsumerPath)
    }).Count
    return [pscustomobject]@{
        BaseHead = $baseHead
        LocalUpdaterState = if ($updaterCount -eq 0) {
            'Absent'
        }
        elseif ($updaterCount -eq $adoptionUpdaterAssets.Count) { 'Complete' }
        else { 'Partial' }
        Collisions = @($collisions)
    }
}

function Get-ExactProtocolSourceBlobSha {
    param(
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [Parameter(Mandatory)][string]$TemplatePath
    )

    $sourcePath = Join-Path $ProtocolSource `
        ($TemplatePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Exact protocol source is missing asset '$TemplatePath'."
    }
    if (Test-Path -LiteralPath (Join-Path $ProtocolSource '.git')) {
        $sourceEntry = Get-AdoptionTreeEntry -Repository $ProtocolSource `
            -Commit $ProtocolSha -Path $TemplatePath
        if ($sourceEntry.Mode -cne '100644' -or $sourceEntry.Type -cne 'blob') {
            throw "Exact protocol source asset '$TemplatePath' is not a regular blob."
        }
        return [string]$sourceEntry.Sha
    }
    return Get-GitBlobSha -Bytes ([IO.File]::ReadAllBytes($sourcePath))
}

function Assert-AdoptionUpdaterAssetsExact {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [string]$Commit = '',
        [switch]$UseIndex
    )

    if ($UseIndex -eq [bool]$Commit) {
        throw 'Exactly one updater validation tree source must be selected.'
    }
    foreach ($asset in $adoptionUpdaterAssets) {
        $sourceSha = Get-ExactProtocolSourceBlobSha -ProtocolSource $ProtocolSource `
            -ProtocolSha $ProtocolSha -TemplatePath ([string]$asset.TemplatePath)
        $consumerEntry = if ($UseIndex) {
            Get-AdoptionTreeEntry -Repository $Repository -Path ([string]$asset.ConsumerPath) `
                -UseIndex
        }
        else {
            Get-AdoptionTreeEntry -Repository $Repository -Path ([string]$asset.ConsumerPath) `
                -Commit $Commit
        }
        if ($consumerEntry.Mode -cne '100644' -or $consumerEntry.Type -cne 'blob' -or
            $consumerEntry.Sha -cne $sourceSha) {
            throw "Consumer updater asset '$($asset.ConsumerPath)' does not match the exact protocol source."
        }
    }
}

function Test-ExactOrdinalPathSet {
    param(
        [Parameter(Mandatory)][object[]]$Actual,
        [Parameter(Mandatory)][object[]]$Expected
    )

    if ($Actual.Count -ne $Expected.Count) {
        return $false
    }
    $remaining = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($path in $Expected) {
        if (-not $remaining.Add([string]$path)) {
            return $false
        }
    }
    foreach ($path in $Actual) {
        if (-not $remaining.Remove([string]$path)) {
            return $false
        }
    }
    return $remaining.Count -eq 0
}

function Assert-ExactAdoptionProposal {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$ProposalHead,
        [Parameter(Mandatory)][string]$CanonicalBaseHead,
        [Parameter(Mandatory)][ValidateSet('Full', 'ManifestOnly')]
        [string]$ProposalMode,
        [Parameter(Mandatory)][string[]]$TargetPaths,
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ProtocolSha
    )

    if ($CanonicalBaseHead -cnotmatch '^[0-9a-f]{40}$' -or
        $ProtocolSha -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The exact adoption proposal received an invalid base or protocol commit.'
    }
    $proposalParent = Get-SingleCommitParent -Repository $Repository `
        -Commit $ProposalHead
    if ($proposalParent -cne $CanonicalBaseHead) {
        throw 'The adoption proposal is not based on the canonical consumer head.'
    }

    $mappedTargetPaths = @('.gitmodules', '.ai/protocol') + @(
        $adoptionAssets | ForEach-Object { [string]$_.ConsumerPath }
    )
    if (-not (Test-ExactOrdinalPathSet -Actual @($TargetPaths) `
        -Expected $mappedTargetPaths)) {
        throw 'The exact protocol target paths do not match the launcher asset mapping.'
    }
    $expectedChangedPaths = if ($ProposalMode -ceq 'Full') {
        @($TargetPaths) + @($adoptionManifestPath)
    }
    else {
        @($adoptionManifestPath)
    }
    Invoke-Git -Repository $Repository -Arguments @(
        'diff', '--check', $CanonicalBaseHead, $ProposalHead, '--'
    ) | Out-Null
    $actualChangedPaths = @((Invoke-Git -Repository $Repository -Arguments @(
        'diff', '--no-renames', '--name-only', '--diff-filter=ACMRTD',
        $CanonicalBaseHead, $ProposalHead, '--'
    )).Output | Where-Object { $_ } | ForEach-Object { [string]$_ })
    if (-not (Test-ExactOrdinalPathSet -Actual $actualChangedPaths `
        -Expected $expectedChangedPaths)) {
        throw 'The adoption proposal does not contain the exact lifecycle change set.'
    }

    if ($ProposalMode -ceq 'ManifestOnly') {
        return
    }

    $protocolEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $ProposalHead -Path '.ai/protocol'
    if ($protocolEntry.Mode -cne '160000' -or
        $protocolEntry.Type -cne 'commit' -or
        $protocolEntry.Sha -cne $ProtocolSha) {
        throw 'The exact adoption proposal protocol reference is not the pinned gitlink.'
    }

    $gitmodulesText = @(
        '[submodule ".ai/protocol"]',
        "`tpath = .ai/protocol",
        "`turl = https://github.com/$ProtocolRepository.git",
        ''
    ) -join "`n"
    $gitmodulesSha = Get-GitBlobSha -Bytes (
        [Text.UTF8Encoding]::new($false).GetBytes($gitmodulesText)
    )
    $gitmodulesEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $ProposalHead -Path '.gitmodules'
    if ($gitmodulesEntry.Mode -cne '100644' -or
        $gitmodulesEntry.Type -cne 'blob' -or
        $gitmodulesEntry.Sha -cne $gitmodulesSha) {
        throw 'The exact adoption proposal submodule metadata is not canonical.'
    }

    foreach ($asset in $adoptionAssets) {
        $sourceSha = Get-ExactProtocolSourceBlobSha `
            -ProtocolSource $ProtocolSource -ProtocolSha $ProtocolSha `
            -TemplatePath ([string]$asset.TemplatePath)
        $proposalEntry = Get-AdoptionTreeEntry -Repository $Repository `
            -Commit $ProposalHead -Path ([string]$asset.ConsumerPath)
        if ($proposalEntry.Mode -cne '100644' -or
            $proposalEntry.Type -cne 'blob' -or
            $proposalEntry.Sha -cne $sourceSha) {
            throw "Adoption proposal asset '$($asset.ConsumerPath)' does not match the exact protocol source."
        }
    }
}

function Get-GitHubSlugFromRemote {
    param([Parameter(Mandatory)][string]$RemoteUrl)

    $candidate = $RemoteUrl.Trim()
    $path = $null
    if ($candidate -match '^https://github\.com/(?<path>[^?#]+)$') {
        $path = $Matches.path
    }
    elseif ($candidate -match '^git@github\.com:(?<path>.+)$') {
        $path = $Matches.path
    }
    elseif ($candidate -match '^ssh://git@github\.com/(?<path>.+)$') {
        $path = $Matches.path
    }

    if (-not $path) {
        throw "Remote '$RemoteName' must be an unambiguous GitHub HTTPS or SSH URL."
    }

    $path = $path.Trim('/')
    if ($path.EndsWith('.git', [StringComparison]::OrdinalIgnoreCase)) {
        $path = $path.Substring(0, $path.Length - 4)
    }
    $parts = @($path.Split('/'))
    if ($parts.Count -ne 2 -or -not $parts[0] -or -not $parts[1]) {
        throw "Remote '$RemoteName' does not identify exactly one GitHub owner/repository."
    }
    return "$($parts[0])/$($parts[1])"
}

function Add-LocalTokenExcludes {
    param([Parameter(Mandatory)][string]$Repository)

    $result = Invoke-Git -Repository $Repository -Arguments @('rev-parse', '--git-path', 'info/exclude')
    $excludePath = (@($result.Output) -join '').Trim()
    if (-not [IO.Path]::IsPathRooted($excludePath)) {
        $excludePath = Join-Path $Repository $excludePath
    }
    $excludePath = [IO.Path]::GetFullPath($excludePath)
    $excludeDirectory = Split-Path -Parent $excludePath
    [IO.Directory]::CreateDirectory($excludeDirectory) | Out-Null

    $existing = if (Test-Path -LiteralPath $excludePath -PathType Leaf) {
        @([IO.File]::ReadAllLines($excludePath))
    }
    else {
        @()
    }
    $updated = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $existing) {
        $updated.Add($line)
    }
    foreach ($name in $tokenMappings.Keys) {
        if ($updated -cnotcontains $name) {
            $updated.Add($name)
        }
    }
    [IO.File]::WriteAllLines($excludePath, $updated, [Text.UTF8Encoding]::new($false))
}

function Assert-TokenFilesAreLocalOnly {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [string[]]$RequiredFileNames = @()
    )

    $head = Invoke-Git -Repository $Repository -Arguments @(
        'rev-parse', '--verify', 'HEAD'
    ) -AllowFailure
    $hasHead = $head.ExitCode -eq 0
    if ($hasHead) {
        $shallow = Invoke-Git -Repository $Repository -Arguments @(
            'rev-parse', '--is-shallow-repository'
        ) -AllowFailure
        $shallowText = ((@($shallow.Output) -join '').Trim())
        if ($shallow.ExitCode -ne 0 -or $shallowText -cnotin @('true', 'false')) {
            throw 'The launcher could not determine whether repository history is complete.'
        }
        if ($shallowText -ceq 'true') {
            throw 'Credential-history validation requires a non-shallow repository. Fetch complete history before rerunning.'
        }
    }

    foreach ($name in $tokenMappings.Keys) {
        $path = Join-Path $Repository $name
        $exists = Test-Path -LiteralPath $path -PathType Leaf

        $tracked = Invoke-Git -Repository $Repository -Arguments @(
            'ls-files', '--error-unmatch', '--', $name
        ) -AllowFailure
        if ($tracked.ExitCode -eq 0) {
            throw "Credential file '$name' is tracked or staged. Remove it from Git, rotate that token, and rerun."
        }

        if ($hasHead) {
            $history = Invoke-Git -Repository $Repository -Arguments @(
                'log', '--all', '--reflog', '--format=%H', '--', $name
            ) -AllowFailure
            if ($history.ExitCode -ne 0) {
                throw "Credential history for '$name' could not be inspected."
            }
            if ((@($history.Output) -join '').Trim()) {
                throw "Credential file '$name' appears in locally reachable ref or reflog history. Rotate that token and clean the history before rerunning."
            }
        }

        if (-not $exists -and $RequiredFileNames -ccontains $name) {
            throw "Required local credential file '$name' is missing from the target root."
        }
    }
}

function Read-LocalToken {
    param([Parameter(Mandatory)][string]$Path)

    $value = [IO.File]::ReadAllText($Path).Trim()
    if (-not $value -or $value -match '\s') {
        throw "Credential file '$([IO.Path]::GetFileName($Path))' must contain exactly one non-whitespace token value."
    }
    return $value
}

function Invoke-GitHubApi {
    param(
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][string]$Token
    )

    $headers = @{
        Accept = 'application/vnd.github+json'
        Authorization = "Bearer $Token"
        'X-GitHub-Api-Version' = '2026-03-10'
        'User-Agent' = 'meAndAI-quick-adoption'
    }
    try {
        return Invoke-RestMethod -Method Get -Uri $Uri -Headers $headers
    }
    catch {
        throw "GitHub API access failed for the requested repository resource. Verify token scope and repository access, then rerun."
    }
}

function Get-ValidatedImmutableProtocolRelease {
    param([string]$ProtocolToken = '')

    $escapedTag = [Uri]::EscapeDataString($ProtocolTag)
    $endpoint = "repos/$ProtocolRepository/releases/tags/$escapedTag"
    if ($ProtocolToken) {
        $release = Invoke-GitHubApi `
            -Uri "https://api.github.com/$endpoint" -Token $ProtocolToken
    }
    else {
        try {
            $result = Invoke-External -Command 'gh' -Arguments @(
                'api',
                '-H', 'Accept: application/vnd.github+json',
                '-H', 'X-GitHub-Api-Version: 2026-03-10',
                $endpoint
            )
            $release = ((@($result.Output) -join [Environment]::NewLine) |
                ConvertFrom-Json)
        }
        catch {
            throw "Unable to verify the published immutable GitHub Release '$ProtocolTag' through the authenticated local GitHub CLI."
        }
    }

    $requiredProperties = @('tag_name', 'draft', 'prerelease', 'immutable', 'published_at')
    foreach ($property in $requiredProperties) {
        if ($null -eq $release -or $null -eq $release.PSObject.Properties[$property]) {
            throw "The published immutable GitHub Release response is missing '$property'."
        }
    }
    $publishedAt = [DateTimeOffset]::MinValue
    if ([string]$release.tag_name -cne $ProtocolTag -or
        $release.draft -isnot [bool] -or $release.draft -or
        $release.prerelease -isnot [bool] -or $release.prerelease -or
        $release.immutable -isnot [bool] -or -not $release.immutable -or
        -not [DateTimeOffset]::TryParse([string]$release.published_at, [ref]$publishedAt)) {
        throw "Protocol source '$ProtocolTag' is not an exact published immutable GitHub Release."
    }

    return $release
}

function Get-CanonicalWorkflow {
    param([string]$ProtocolToken = '')

    if ($ProtocolRepository -cnotmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        throw "ProtocolRepository '$ProtocolRepository' must use the owner/repository form."
    }
    if ($ProtocolTag -cnotmatch '^v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)$') {
        throw 'ProtocolTag must use the vM.m.rev form.'
    }

    [void](Get-ValidatedImmutableProtocolRelease -ProtocolToken $ProtocolToken)

    $escapedRef = [Uri]::EscapeDataString($ProtocolTag)
    $uri = "https://api.github.com/repos/$ProtocolRepository/contents/$workflowSourcePath`?ref=$escapedRef"
    if ($ProtocolToken) {
        $response = Invoke-GitHubApi -Uri $uri -Token $ProtocolToken
    }
    else {
        $endpoint = "repos/$ProtocolRepository/contents/$workflowSourcePath`?ref=$escapedRef"
        try {
            $result = Invoke-External -Command 'gh' -Arguments @(
                'api',
                '-H', 'Accept: application/vnd.github+json',
                '-H', 'X-GitHub-Api-Version: 2026-03-10',
                $endpoint
            )
            $response = ((@($result.Output) -join [Environment]::NewLine) | ConvertFrom-Json)
        }
        catch {
            throw "Unable to retrieve the canonical workflow through the authenticated local GitHub CLI. Verify local gh access to '$ProtocolRepository', then rerun."
        }
    }
    if ($response.encoding -cne 'base64' -or -not $response.content -or -not $response.sha) {
        throw 'The canonical workflow response is incomplete or uses an unsupported encoding.'
    }

    try {
        $bytes = [Convert]::FromBase64String(([string]$response.content))
    }
    catch {
        throw 'The canonical workflow response contains invalid base64 content.'
    }
    $actualSha = Get-GitBlobSha -Bytes $bytes
    if ($actualSha -cne ([string]$response.sha).ToLowerInvariant()) {
        throw 'The canonical workflow Git blob verification failed.'
    }
    return $bytes
}

function Set-RepositorySecret {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    # gh secret set reads the value from stdin when no body argument is used.
    try {
        Invoke-External -Command 'gh' -Arguments @(
            'secret', 'set', $Name, '--repo', $Repository
        ) -InputText $Value | Out-Null
    }
    catch {
        throw "Unable to store repository Actions secret '$Name'."
    }
}

function Get-RepositorySecretNames {
    param([Parameter(Mandatory)][string]$Repository)

    # gh secret list exposes repository secret names, never their stored values.
    $listed = Invoke-External -Command 'gh' -Arguments @(
        'secret', 'list', '--repo', $Repository, '--json', 'name'
    )
    try {
        $items = @(((@($listed.Output) -join [Environment]::NewLine) | ConvertFrom-Json))
    }
    catch {
        throw 'GitHub CLI returned invalid repository Actions secret metadata.'
    }

    $names = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $items) {
        if ($null -eq $item -or $null -eq $item.PSObject.Properties['name']) {
            throw 'GitHub CLI returned incomplete repository Actions secret metadata.'
        }
        $name = ([string]$item.name).Trim()
        if (-not $name) {
            throw 'GitHub CLI returned an empty repository Actions secret name.'
        }
        if ($names -notcontains $name) {
            $names.Add($name)
        }
    }
    return @($names)
}

function Get-RepositoryLabelRecord {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Name
    )

    $encodedName = [Uri]::EscapeDataString($Name)
    $view = Invoke-External -Command 'gh' -Arguments @(
        'api',
        '-H', 'Accept: application/vnd.github+json',
        '-H', 'X-GitHub-Api-Version: 2026-03-10',
        "repos/$Repository/labels/$encodedName"
    )
    try {
        $label = ((@($view.Output) -join [Environment]::NewLine) | ConvertFrom-Json)
    }
    catch {
        throw "GitHub CLI returned invalid metadata for repository label '$Name'."
    }
    if ($null -eq $label -or $null -eq $label.PSObject.Properties['name'] -or
        $null -eq $label.PSObject.Properties['description'] -or
        [string]$label.name -cne $Name) {
        throw "Repository label '$Name' has incomplete or mismatched identity metadata."
    }
    return $label
}

function Enter-RepositorySecretReconciliationLock {
    param([Parameter(Mandatory)][string]$Repository)

    $nonce = [guid]::NewGuid().ToString('N')
    $description = "meAndAI secret reconciliation lock session $nonce"
    $created = Invoke-External -Command 'gh' -Arguments @(
        'label', 'create', $secretLockLabel, '--repo', $Repository,
        '--color', 'ededed', '--description', $description
    ) -AllowFailure
    if ($created.ExitCode -ne 0) {
        throw "Repository secret reconciliation is already locked or a stale '$secretLockLabel' label exists. Inspect the label and resolve ownership manually before rerunning."
    }

    $observed = Get-RepositoryLabelRecord -Repository $Repository -Name $secretLockLabel
    if ([string]$observed.description -cne $description) {
        throw 'The repository secret-reconciliation lock could not be verified after creation.'
    }
    return [pscustomobject]@{
        Name = $secretLockLabel
        Description = $description
    }
}

function Exit-RepositorySecretReconciliationLock {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$Lock
    )

    $observed = Get-RepositoryLabelRecord -Repository $Repository -Name ([string]$Lock.Name)
    if ([string]$observed.description -cne [string]$Lock.Description) {
        throw 'The repository secret-reconciliation lock ownership changed; the launcher did not remove it.'
    }
    $encodedName = [Uri]::EscapeDataString([string]$Lock.Name)
    Invoke-External -Command 'gh' -Arguments @(
        'api', '--method', 'DELETE',
        '-H', 'Accept: application/vnd.github+json',
        '-H', 'X-GitHub-Api-Version: 2026-03-10',
        "repos/$Repository/labels/$encodedName"
    ) | Out-Null
}

function Write-CanonicalWorkflow {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][byte[]]$Bytes
    )

    $directory = Split-Path -Parent $Path
    [IO.Directory]::CreateDirectory($directory) | Out-Null
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $current = [IO.File]::ReadAllBytes($Path)
        if (-not (Test-ByteArrayEqual -Left $current -Right $Bytes)) {
            throw "The existing '$workflowTargetPath' differs from the canonical $ProtocolTag seed; it was not overwritten."
        }
        return $false
    }

    $temporaryPath = Join-Path $directory ".meandai-seed-$([guid]::NewGuid().ToString('N')).tmp"
    try {
        [IO.File]::WriteAllBytes($temporaryPath, $Bytes)
        Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
    return $true
}

function Invoke-LifecycleWorkflow {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][string]$HeadSha
    )

    $workflowName = [IO.Path]::GetFileName($workflowTargetPath)
    $correlationId = [guid]::NewGuid().ToString('N')
    $expectedRunTitle = "meAndAI AI capabilities lifecycle [$correlationId]"
    $registered = $false
    for ($attempt = 1; $attempt -le 6; $attempt++) {
        $view = Invoke-External -Command 'gh' -Arguments @(
            'workflow', 'view', $workflowName, '--repo', $Repository,
            '--ref', $Branch, '--yaml'
        ) -AllowFailure
        if ($view.ExitCode -eq 0) {
            $registered = $true
            break
        }
        if ($attempt -lt 6) {
            Start-Sleep -Seconds 5
        }
    }
    if (-not $registered) {
        throw 'The lifecycle workflow was published but did not become discoverable after six bounded attempts.'
    }

    $listArguments = @(
        'run', 'list', '--repo', $Repository, '--workflow', $workflowName,
        '--event', 'workflow_dispatch', '--branch', $Branch, '--commit', $HeadSha,
        '--limit', '100', '--json', 'databaseId,createdAt,displayTitle,headSha,status,conclusion,url'
    )
    $baselineResult = Invoke-External -Command 'gh' -Arguments $listArguments
    try {
        $baselineRuns = @(((@($baselineResult.Output) -join [Environment]::NewLine) | ConvertFrom-Json))
    }
    catch {
        throw 'GitHub CLI returned invalid baseline workflow-run metadata.'
    }
    $baselineIds = [System.Collections.Generic.HashSet[long]]::new()
    foreach ($run in $baselineRuns) {
        if ($null -eq $run.PSObject.Properties['databaseId'] -or
            [string]$run.databaseId -cnotmatch '^[1-9][0-9]*$') {
            throw 'GitHub CLI returned an invalid baseline workflow-run identity.'
        }
        [void]$baselineIds.Add([long]$run.databaseId)
    }

    $dispatchStarted = [DateTimeOffset]::UtcNow.AddSeconds(-5)
    Invoke-External -Command 'gh' -Arguments @(
        'workflow', 'run', $workflowName, '--repo', $Repository, '--ref', $Branch,
        '--field', "correlation_id=$correlationId"
    ) | Out-Null

    $deadline = [DateTimeOffset]::UtcNow.AddMinutes($WorkflowTimeoutMinutes)
    $observedRunId = $null
    while ([DateTimeOffset]::UtcNow -lt $deadline) {
        if ($null -eq $observedRunId) {
            $list = Invoke-External -Command 'gh' -Arguments $listArguments
            try {
                $runs = @(((@($list.Output) -join [Environment]::NewLine) | ConvertFrom-Json))
            }
            catch {
                throw 'GitHub CLI returned invalid workflow-run metadata.'
            }
            $candidates = [System.Collections.Generic.List[object]]::new()
            foreach ($run in $runs) {
                if ($null -eq $run.PSObject.Properties['databaseId'] -or
                    [string]$run.databaseId -cnotmatch '^[1-9][0-9]*$' -or
                    $null -eq $run.PSObject.Properties['createdAt'] -or
                    $null -eq $run.PSObject.Properties['displayTitle'] -or
                    $null -eq $run.PSObject.Properties['headSha']) {
                    throw 'GitHub CLI returned incomplete workflow-run metadata.'
                }
                try {
                    $createdAt = [DateTimeOffset]::Parse([string]$run.createdAt)
                }
                catch {
                    throw 'GitHub CLI returned an invalid workflow-run timestamp.'
                }
                if (-not $baselineIds.Contains([long]$run.databaseId) -and
                    [string]$run.headSha -ceq $HeadSha -and
                    [string]$run.displayTitle -ceq $expectedRunTitle -and
                    $createdAt -ge $dispatchStarted) {
                    $candidates.Add($run)
                }
            }
            if ($candidates.Count -gt 1) {
                throw 'More than one unseen lifecycle workflow run matches this dispatch.'
            }
            if ($candidates.Count -eq 1) {
                $observedRunId = [long]$candidates[0].databaseId
            }
        }
        if ($null -ne $observedRunId) {
            $view = Invoke-External -Command 'gh' -Arguments @(
                'run', 'view', [string]$observedRunId, '--repo', $Repository,
                '--json', 'databaseId,displayTitle,headSha,status,conclusion,url'
            )
            try {
                $run = ((@($view.Output) -join [Environment]::NewLine) | ConvertFrom-Json)
            }
            catch {
                throw 'GitHub CLI returned invalid workflow-run detail metadata.'
            }
            if ([long]$run.databaseId -ne [long]$observedRunId -or
                [string]$run.headSha -cne $HeadSha -or
                [string]$run.displayTitle -cne $expectedRunTitle) {
                throw 'The observed lifecycle workflow run no longer matches its dispatch identity.'
            }
            if ([string]$run.status -ceq 'completed') {
                if ([string]$run.conclusion -cne 'success') {
                    throw "The lifecycle workflow completed with '$($run.conclusion)': $($run.url)"
                }
                return $run
            }
        }
        Start-Sleep -Seconds 5
    }

    throw "The lifecycle workflow did not complete within $WorkflowTimeoutMinutes minute(s)."
}

function Get-ValidatedAdoptionMarker {
    param(
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][string]$BaseBranch,
        [Parameter(Mandatory)][string]$ExpectedActor,
        [string]$ExpectedMarkerHead = ''
    )

    $requiredProperties = @(
        'number', 'url', 'isDraft', 'state', 'baseRefName', 'headRefName',
        'headRefOid', 'headRepository', 'author', 'body'
    )
    foreach ($property in $requiredProperties) {
        if ($null -eq $PullRequest.PSObject.Properties[$property]) {
            throw "The deterministic adoption pull request is missing '$property' metadata."
        }
    }
    if ([string]$PullRequest.state -cne 'OPEN' -or
        [string]$PullRequest.baseRefName -cne $BaseBranch -or
        [string]$PullRequest.headRefName -cne $Branch -or
        [string]$PullRequest.headRefOid -cnotmatch '^[0-9a-f]{40}$' -or
        $PullRequest.isDraft -isnot [bool]) {
        throw 'The deterministic adoption pull request has invalid lifecycle metadata.'
    }
    if ($null -eq $PullRequest.headRepository -or
        $null -eq $PullRequest.headRepository.PSObject.Properties['nameWithOwner'] -or
        -not ([string]$PullRequest.headRepository.nameWithOwner).Equals(
            $Repository, [StringComparison]::OrdinalIgnoreCase
        )) {
        throw 'The deterministic adoption pull request does not originate in the target repository.'
    }
    if ($null -eq $PullRequest.author -or
        $null -eq $PullRequest.author.PSObject.Properties['login'] -or
        -not ([string]$PullRequest.author.login).Equals(
            $ExpectedActor, [StringComparison]::OrdinalIgnoreCase
        )) {
        throw 'The deterministic adoption pull request author does not match the authenticated maintainer.'
    }
    if ([string]$PullRequest.number -cnotmatch '^[1-9][0-9]*$' -or
        [string]$PullRequest.url -cnotmatch "/pull/$([regex]::Escape([string]$PullRequest.number))/?$") {
        throw 'The deterministic adoption pull request has invalid identity metadata.'
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
        throw 'The deterministic adoption pull request does not contain one canonical ownership marker.'
    }
    try {
        $marker = $markerMatches[0].Groups['json'].Value | ConvertFrom-Json
    }
    catch {
        throw 'The deterministic adoption pull request ownership marker is invalid JSON.'
    }
    $schemaProperty = $marker.PSObject.Properties['schema']
    if ($null -eq $schemaProperty -or
        ($schemaProperty.Value -isnot [int] -and
         $schemaProperty.Value -isnot [long])) {
        throw 'The deterministic adoption pull request ownership marker has an invalid schema type.'
    }
    $schema = [long]$schemaProperty.Value
    $expectedMarkerProperties = if ($schema -eq 2) {
        @('schema', 'state', 'target', 'protocolSha', 'head', 'repository', 'actor')
    }
    elseif ($schema -eq 3) {
        @('schema', 'phase', 'state', 'target', 'protocolSha', 'head', 'repository', 'actor')
    }
    elseif ($schema -eq 4) {
        @(
            'schema', 'phase', 'state', 'target', 'protocolSha', 'head',
            'previousHead', 'plannedHead', 'repository', 'actor'
        )
    }
    else {
        throw 'The deterministic adoption pull request ownership marker uses an unsupported schema.'
    }
    $actualMarkerProperties = @($marker.PSObject.Properties | ForEach-Object { $_.Name })
    if ($actualMarkerProperties.Count -ne $expectedMarkerProperties.Count -or
        @($expectedMarkerProperties | Where-Object { $actualMarkerProperties -cnotcontains $_ }).Count -ne 0) {
        throw 'The deterministic adoption pull request ownership marker has an unexpected schema.'
    }
    $phase = if ($schema -eq 2) { 'Proposed' } else { [string]$marker.phase }
    if ($phase -cnotin @('Proposed', 'Publishing', 'Completed') -or
        [string]$marker.state -cnotin @('BootstrapReady', 'AdoptionReviewRequired') -or
        [string]$marker.target -cne $ProtocolTag -or
        [string]$marker.protocolSha -cnotmatch '^[0-9a-f]{40}$' -or
        -not ([string]$marker.repository).Equals($Repository, [StringComparison]::OrdinalIgnoreCase) -or
        -not ([string]$marker.actor).Equals($ExpectedActor, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The deterministic adoption pull request ownership marker does not match its live identity.'
    }
    if ($phase -ceq 'Publishing') {
        if ($schema -ne 4 -or
            [string]$marker.previousHead -cnotmatch '^[0-9a-f]{40}$' -or
            [string]$marker.plannedHead -cnotmatch '^[0-9a-f]{40}$' -or
            [string]$marker.previousHead -ceq [string]$marker.plannedHead -or
            [string]$marker.head -cne [string]$marker.previousHead -or
            ([string]$PullRequest.headRefOid -cne [string]$marker.previousHead -and
             [string]$PullRequest.headRefOid -cne [string]$marker.plannedHead) -or
            ($ExpectedMarkerHead -and
             [string]$marker.previousHead -cne $ExpectedMarkerHead)) {
            throw 'The deterministic adoption pull request publishing marker is inconsistent with its live transition.'
        }
    }
    else {
        if ($schema -eq 4) {
            throw 'The deterministic adoption pull request uses the publishing schema outside its publishing phase.'
        }
        $requiredMarkerHead = if ($ExpectedMarkerHead) {
            $ExpectedMarkerHead
        }
        else {
            [string]$PullRequest.headRefOid
        }
        if ($requiredMarkerHead -cnotmatch '^[0-9a-f]{40}$' -or
            [string]$marker.head -cne $requiredMarkerHead) {
            throw 'The deterministic adoption pull request marker head does not match the expected transition state.'
        }
    }
    if ($schema -eq 2) {
        $marker | Add-Member -NotePropertyName phase -NotePropertyValue 'Proposed' -Force
    }
    return $marker
}

function Get-AdoptionPullRequest {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$BaseBranch,
        [Parameter(Mandatory)][string]$ExpectedActor,
        [ValidateRange(1, 6)][int]$MaxAttempts = 6,
        [string]$ExpectedNumber = '',
        [string]$ExpectedUrl = '',
        [string]$ExpectedLiveHead = '',
        [string]$ExpectedMarkerHead = '',
        [string]$ExpectedBody,
        [object]$ExpectedDraft = $null
    )

    $branch = "automation/meandai-capabilities-$ProtocolTag"
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $list = Invoke-External -Command 'gh' -Arguments @(
            'pr', 'list', '--repo', $Repository, '--state', 'open', '--head', $branch,
            '--limit', '10', '--json',
            'number,url,isDraft,state,baseRefName,headRefName,headRefOid,headRepository,author,body'
        )
        try {
            $pullRequests = @(((@($list.Output) -join [Environment]::NewLine) | ConvertFrom-Json))
        }
        catch {
            throw 'GitHub CLI returned invalid adoption pull-request metadata.'
        }
        $matchingPullRequests = @($pullRequests | Where-Object { $_.headRefName -ceq $branch })
        if ($matchingPullRequests.Count -eq 1) {
            $marker = Get-ValidatedAdoptionMarker -PullRequest $matchingPullRequests[0] `
                -Repository $Repository -Branch $branch -BaseBranch $BaseBranch `
                -ExpectedActor $ExpectedActor -ExpectedMarkerHead $ExpectedMarkerHead
            $pullRequest = $matchingPullRequests[0]
            if (($ExpectedNumber -and [string]$pullRequest.number -cne $ExpectedNumber) -or
                ($ExpectedUrl -and [string]$pullRequest.url -cne $ExpectedUrl) -or
                ($ExpectedLiveHead -and [string]$pullRequest.headRefOid -cne $ExpectedLiveHead) -or
                ($PSBoundParameters.ContainsKey('ExpectedBody') -and
                    [string]$pullRequest.body -cne $ExpectedBody) -or
                ($null -ne $ExpectedDraft -and
                    ($ExpectedDraft -isnot [bool] -or [bool]$pullRequest.isDraft -ne [bool]$ExpectedDraft))) {
                throw 'The deterministic adoption pull request changed outside the expected state transition.'
            }
            $pullRequest | Add-Member -NotePropertyName meAndAIMarker `
                -NotePropertyValue $marker -Force
            return $pullRequest
        }
        if ($matchingPullRequests.Count -gt 1) {
            throw 'More than one open deterministic adoption pull request was found.'
        }
        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds 5
        }
    }

    return $null
}

function Set-AdoptionPullRequestMarkerBody {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$MarkerJson,
        [Parameter(Mandatory)][string]$TemporaryDirectory,
        [Parameter(Mandatory)][string]$FileName
    )

    $body = [string]$PullRequest.body
    $matches = [regex]::Matches(
        $body, '<!-- meandai-capabilities-adoption:(?<json>\{[^\r\n]*\}) -->',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if ($matches.Count -ne 1) {
        throw 'The adoption marker cannot be updated because its canonical source is missing or ambiguous.'
    }
    $match = $matches[0]
    $replacement = "<!-- meandai-capabilities-adoption:$MarkerJson -->"
    $updatedBody = $body.Substring(0, $match.Index) + $replacement +
        $body.Substring($match.Index + $match.Length)
    $bodyPath = Join-Path $TemporaryDirectory $FileName
    [IO.File]::WriteAllText(
        $bodyPath, $updatedBody, [Text.UTF8Encoding]::new($false)
    )
    Invoke-External -Command 'gh' -Arguments @(
        'pr', 'edit', [string]$PullRequest.number, '--repo', $Repository,
        '--body-file', $bodyPath
    ) | Out-Null
    return $updatedBody
}

function Set-AdoptionPullRequestPublishingMarker {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$PreviousHead,
        [Parameter(Mandatory)][string]$PlannedHead,
        [Parameter(Mandatory)][string]$TemporaryDirectory
    )

    if ($PreviousHead -cnotmatch '^[0-9a-f]{40}$' -or
        $PlannedHead -cnotmatch '^[0-9a-f]{40}$' -or
        $PreviousHead -ceq $PlannedHead) {
        throw 'The adoption publishing transition has invalid commit identities.'
    }
    $marker = $PullRequest.meAndAIMarker
    $publishingMarker = [ordered]@{
        schema = 4
        phase = 'Publishing'
        state = [string]$marker.state
        target = [string]$marker.target
        protocolSha = [string]$marker.protocolSha
        head = $PreviousHead
        previousHead = $PreviousHead
        plannedHead = $PlannedHead
        repository = [string]$marker.repository
        actor = [string]$marker.actor
    } | ConvertTo-Json -Compress
    return Set-AdoptionPullRequestMarkerBody -Repository $Repository `
        -PullRequest $PullRequest -MarkerJson $publishingMarker `
        -TemporaryDirectory $TemporaryDirectory -FileName 'publishing-adoption-pr.md'
}

function Set-AdoptionPullRequestProposedMarker {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$PreviousHead,
        [Parameter(Mandatory)][string]$TemporaryDirectory
    )

    if ($PreviousHead -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The restored adoption proposal head is invalid.'
    }
    $marker = $PullRequest.meAndAIMarker
    $proposedMarker = [ordered]@{
        schema = 3
        phase = 'Proposed'
        state = [string]$marker.state
        target = [string]$marker.target
        protocolSha = [string]$marker.protocolSha
        head = $PreviousHead
        repository = [string]$marker.repository
        actor = [string]$marker.actor
    } | ConvertTo-Json -Compress
    return Set-AdoptionPullRequestMarkerBody -Repository $Repository `
        -PullRequest $PullRequest -MarkerJson $proposedMarker `
        -TemporaryDirectory $TemporaryDirectory -FileName 'proposed-adoption-pr.md'
}

function Set-AdoptionPullRequestCompletedMarker {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$PublishedHead,
        [Parameter(Mandatory)][string]$TemporaryDirectory
    )

    if ($PublishedHead -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The completed adoption head is invalid.'
    }
    $marker = $PullRequest.meAndAIMarker
    $completedMarker = [ordered]@{
        schema = 3
        phase = 'Completed'
        state = [string]$marker.state
        target = [string]$marker.target
        protocolSha = [string]$marker.protocolSha
        head = $PublishedHead
        repository = [string]$marker.repository
        actor = [string]$marker.actor
    } | ConvertTo-Json -Compress
    return Set-AdoptionPullRequestMarkerBody -Repository $Repository `
        -PullRequest $PullRequest -MarkerJson $completedMarker `
        -TemporaryDirectory $TemporaryDirectory -FileName 'completed-adoption-pr.md'
}

function Get-RevalidatedAdoptionPullRequest {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$OriginalPullRequest,
        [Parameter(Mandatory)][string]$LiveHead,
        [Parameter(Mandatory)][string]$MarkerHead,
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)][bool]$Draft
    )

    return Get-AdoptionPullRequest -Repository $Repository `
        -BaseBranch ([string]$OriginalPullRequest.baseRefName) `
        -ExpectedActor ([string]$OriginalPullRequest.meAndAIMarker.actor) `
        -MaxAttempts 1 -ExpectedNumber ([string]$OriginalPullRequest.number) `
        -ExpectedUrl ([string]$OriginalPullRequest.url) -ExpectedLiveHead $LiveHead `
        -ExpectedMarkerHead $MarkerHead -ExpectedBody $Body -ExpectedDraft $Draft
}

function Complete-AdoptionReviewTransition {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$PublishedHead,
        [Parameter(Mandatory)][string]$ExpectedMarkerHead,
        [Parameter(Mandatory)][string]$TemporaryDirectory,
        [Parameter(Mandatory)]$Issue,
        [switch]$PersistCompletedMarker
    )

    $body = [string]$PullRequest.body
    $current = Get-RevalidatedAdoptionPullRequest -Repository $Repository `
        -OriginalPullRequest $PullRequest -LiveHead $PublishedHead `
        -MarkerHead $ExpectedMarkerHead -Body $body `
        -Draft ([bool]$PullRequest.isDraft)
    if ($PersistCompletedMarker) {
        if (-not [bool]$current.isDraft) {
            throw 'The adoption proposal became ready before its completed marker was persisted.'
        }
        $body = Set-AdoptionPullRequestCompletedMarker -Repository $Repository `
            -PullRequest $current -PublishedHead $PublishedHead `
            -TemporaryDirectory $TemporaryDirectory
        $current = Get-RevalidatedAdoptionPullRequest -Repository $Repository `
            -OriginalPullRequest $current -LiveHead $PublishedHead `
            -MarkerHead $PublishedHead -Body $body -Draft $true
    }
    if ([bool]$current.isDraft) {
        Invoke-External -Command 'gh' -Arguments @(
            'pr', 'ready', [string]$current.number, '--repo', $Repository
        ) | Out-Null
        $current = Get-RevalidatedAdoptionPullRequest -Repository $Repository `
            -OriginalPullRequest $current -LiveHead $PublishedHead `
            -MarkerHead $PublishedHead -Body $body -Draft $false
    }
    Set-AdoptionIssueReadyForReview -Repository $Repository -Issue $Issue
    return $current
}

function Ensure-AdoptionLabels {
    param([Parameter(Mandatory)][string]$Repository)

    $list = Invoke-External -Command 'gh' -Arguments @(
        'label', 'list', '--repo', $Repository, '--limit', '1000', '--json', 'name'
    )
    try {
        $parsed = ((@($list.Output) -join [Environment]::NewLine) | ConvertFrom-Json)
        $existing = @($parsed | Where-Object { $null -ne $_ })
    }
    catch {
        throw 'GitHub CLI returned invalid repository-label metadata.'
    }

    $names = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($label in $existing) {
        if ($null -eq $label.PSObject.Properties['name'] -or
            [string]::IsNullOrWhiteSpace([string]$label.name)) {
            throw 'GitHub CLI returned an invalid repository label.'
        }
        [void]$names.Add([string]$label.name)
    }

    foreach ($label in $adoptionLabels) {
        if ($names.Contains([string]$label.Name)) {
            continue
        }
        Invoke-External -Command 'gh' -Arguments @(
            'label', 'create', [string]$label.Name, '--repo', $Repository,
            '--color', [string]$label.Color, '--description', [string]$label.Description
        ) | Out-Null
        [void]$names.Add([string]$label.Name)
    }
}

function Get-AdoptionIssueInventory {
    param([Parameter(Mandatory)][string]$Repository)

    $list = Invoke-External -Command 'gh' -Arguments @(
        'issue', 'list', '--repo', $Repository, '--state', 'all', '--limit', '1000',
        '--json', 'number,url,title,body,state'
    )
    try {
        $parsed = ((@($list.Output) -join [Environment]::NewLine) | ConvertFrom-Json)
        return @($parsed | Where-Object { $null -ne $_ })
    }
    catch {
        throw 'GitHub CLI returned invalid adoption-issue metadata.'
    }
}

function Get-MarkedAdoptionIssues {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Issues,
        [Parameter(Mandatory)][string]$Marker,
        [Parameter(Mandatory)][string]$ExpectedTitle,
        [Parameter(Mandatory)][string]$ExpectedBody
    )

    $numbers = [System.Collections.Generic.HashSet[int]]::new()
    $canonicalMarkerPattern = '\A' + [regex]::Escape($Marker) + '(?:\r?\n|\z)'
    $ownershipPrefix = $Marker.Substring(0, $Marker.Length - ' -->'.Length)
    $matching = [System.Collections.Generic.List[object]]::new()
    $normalizedExpectedBody = $ExpectedBody.Replace("`r`n", "`n").TrimEnd([char[]]"`r`n")
    foreach ($issue in $Issues) {
        if ($null -eq $issue.PSObject.Properties['body']) {
            continue
        }
        $body = [string]$issue.body
        $hasOwnedPrefix = $body.StartsWith(
            $ownershipPrefix, [StringComparison]::OrdinalIgnoreCase
        )
        $canonicalLines = [regex]::Matches(
            $body,
            '(?m)^' + [regex]::Escape($Marker) + '\r?$'
        )
        if (-not [regex]::IsMatch($body, $canonicalMarkerPattern)) {
            if ($hasOwnedPrefix) {
                throw 'A project-owned adoption issue contains a malformed ownership marker; manual review is required.'
            }
            continue
        }
        foreach ($property in @('number', 'url', 'title', 'body', 'state')) {
            if ($null -eq $issue.PSObject.Properties[$property]) {
                throw 'A project-owned adoption issue has incomplete identity metadata.'
            }
        }
        $normalizedBody = $body.Replace("`r`n", "`n").TrimEnd([char[]]"`r`n")
        if ($canonicalLines.Count -ne 1 -or
            [string]$issue.title -cne $ExpectedTitle -or
            $normalizedBody -cne $normalizedExpectedBody) {
            throw 'A canonically marked adoption issue has drifted from its exact owned record; manual review is required.'
        }
        if ([string]$issue.number -cnotmatch '^[1-9][0-9]*$' -or
            [string]$issue.url -notmatch '^https://github\.com/[^/]+/[^/]+/issues/[1-9][0-9]*/?$' -or
            [string]$issue.state -cnotin @('OPEN', 'CLOSED') -or
            -not $numbers.Add([int]$issue.number)) {
            throw 'A project-owned adoption issue has invalid or duplicate identity metadata.'
        }
        $matching.Add($issue)
    }
    return @($matching | Sort-Object { [int]$_.number })
}

function Ensure-AdoptionIssue {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$TemporaryDirectory
    )

    $marker = '<!-- meandai-local-adoption:{0}:pr-{1} -->' -f `
        $ProtocolTag, [string]$PullRequest.number
    $issueTitle = "Track meAndAI AI capabilities adoption from $ProtocolTag"
    $issueBody = @(
        $marker,
        '## AI capabilities adoption tracking',
        '',
        "- Protocol release: ``$ProtocolTag``",
        "- Adoption draft: $($PullRequest.url)",
        '',
        'This issue tracks the project-owned feature and decision records, local memory, tests, evidence, links, and maintainer review required to complete the transient adoption manifest.',
        '',
        'The launcher may prepare the draft and mark it ready after bounded local validation; only the maintainer may merge it.'
    ) -join [Environment]::NewLine
    $completed = [string]$PullRequest.meAndAIMarker.phase -ceq 'Completed'
    $desiredStatusLabel = if ($completed) {
        'status:needs-review'
    }
    else { 'status:in-progress' }
    $supersededStatusLabel = if ($completed) {
        'status:in-progress'
    }
    else { 'status:needs-review' }
    $matchingIssues = @(Get-MarkedAdoptionIssues `
        -Issues @(Get-AdoptionIssueInventory -Repository $Repository) -Marker $marker `
        -ExpectedTitle $issueTitle -ExpectedBody $issueBody)

    if ($matchingIssues.Count -eq 0) {
        $bodyPath = Join-Path $TemporaryDirectory 'adoption-issue.md'
        [IO.File]::WriteAllText(
            $bodyPath, $issueBody + [Environment]::NewLine,
            [Text.UTF8Encoding]::new($false)
        )
        $created = Invoke-External -Command 'gh' -Arguments @(
            'issue', 'create', '--repo', $Repository,
            '--title', $issueTitle,
            '--body-file', $bodyPath,
            '--label', 'type:feature', '--label', 'priority:p1',
            '--label', $desiredStatusLabel
        )
        $createdUrl = ((@($created.Output) -join [Environment]::NewLine).Trim())
        if ($createdUrl -notmatch '^https://github\.com/[^/]+/[^/]+/issues/[1-9][0-9]*/?$') {
            throw 'Created adoption issue returned an unrecognized URL.'
        }
        $matchingIssues = @(Get-MarkedAdoptionIssues `
            -Issues @(Get-AdoptionIssueInventory -Repository $Repository) -Marker $marker `
            -ExpectedTitle $issueTitle -ExpectedBody $issueBody)
    }

    if ($matchingIssues.Count -eq 0) {
        throw 'The created adoption issue was not observable during convergence.'
    }
    $canonicalNumber = [int]$matchingIssues[0].number
    if ([string]$matchingIssues[0].state -ceq 'CLOSED') {
        Invoke-External -Command 'gh' -Arguments @(
            'issue', 'reopen', [string]$canonicalNumber, '--repo', $Repository
        ) | Out-Null
    }
    foreach ($duplicate in @($matchingIssues | Select-Object -Skip 1)) {
        if ([string]$duplicate.state -ceq 'OPEN') {
            Invoke-External -Command 'gh' -Arguments @(
                'issue', 'close', [string]$duplicate.number, '--repo', $Repository
            ) | Out-Null
        }
    }

    $converged = @(Get-MarkedAdoptionIssues `
        -Issues @(Get-AdoptionIssueInventory -Repository $Repository) -Marker $marker `
        -ExpectedTitle $issueTitle -ExpectedBody $issueBody |
        Where-Object { [string]$_.state -ceq 'OPEN' })
    if ($converged.Count -ne 1 -or [int]$converged[0].number -ne $canonicalNumber) {
        throw 'Project-owned adoption issues did not converge to one canonical open identity.'
    }
    Invoke-External -Command 'gh' -Arguments @(
        'issue', 'edit', [string]$canonicalNumber, '--repo', $Repository,
        '--add-label', 'type:feature', '--add-label', 'priority:p1',
        '--add-label', $desiredStatusLabel,
        '--remove-label', $supersededStatusLabel
    ) | Out-Null
    return $converged[0]
}

function Set-AdoptionIssueReadyForReview {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$Issue
    )

    Invoke-External -Command 'gh' -Arguments @(
        'issue', 'edit', [string]$Issue.number, '--repo', $Repository,
        '--remove-label', 'status:in-progress',
        '--add-label', 'status:needs-review'
    ) | Out-Null
}

function ConvertTo-ProcessArgument {
    param([AllowEmptyString()][Parameter(Mandatory)][string]$Value)

    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') {
        return $Value
    }
    $builder = [Text.StringBuilder]::new()
    [void]$builder.Append('"')
    $backslashes = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq '\') {
            $backslashes++
            continue
        }
        if ($character -eq '"') {
            [void]$builder.Append(('\' * (($backslashes * 2) + 1)))
            [void]$builder.Append('"')
            $backslashes = 0
            continue
        }
        if ($backslashes -gt 0) {
            [void]$builder.Append(('\' * $backslashes))
            $backslashes = 0
        }
        [void]$builder.Append($character)
    }
    if ($backslashes -gt 0) {
        [void]$builder.Append(('\' * ($backslashes * 2)))
    }
    [void]$builder.Append('"')
    return $builder.ToString()
}

function New-ExternalProcessRunner {
    param(
        [Parameter(Mandatory)]$CommandInfo,
        [string[]]$PrefixArguments = @(),
        [Parameter(Mandatory)][string]$Description
    )

    if ($CommandInfo.CommandType -eq [Management.Automation.CommandTypes]::Application) {
        $extension = [IO.Path]::GetExtension([string]$CommandInfo.Source)
        if ($extension -in @('.cmd', '.bat')) {
            if ($env:OS -cne 'Windows_NT' -or -not $env:ComSpec) {
                throw "The $Description resolved to a Windows command wrapper on a non-Windows host."
            }
            return [pscustomobject]@{
                Command = [string]$env:ComSpec
                PrefixArguments = @('/d', '/c', 'call', [string]$CommandInfo.Source) + @($PrefixArguments)
                Description = $Description
            }
        }
        return [pscustomobject]@{
            Command = [string]$CommandInfo.Source
            PrefixArguments = @($PrefixArguments)
            Description = $Description
        }
    }
    throw "The $Description must resolve to a native executable or command wrapper."
}

function Resolve-LocalCodexRunner {
    param(
        [string]$ExplicitCommand,
        [Parameter(Mandatory)][string]$FallbackVersion
    )

    if ($FallbackVersion -cnotmatch '^\d+\.\d+\.\d+$') {
        throw 'TemporaryCodexVersion must use the M.m.rev form.'
    }

    $installedName = if ($ExplicitCommand) { $ExplicitCommand } else { 'codex' }
    $installed = @(Get-Command $installedName -All -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandType -eq [Management.Automation.CommandTypes]::Application } |
        Select-Object -First 1)
    if ($installed.Count -eq 1) {
        return New-ExternalProcessRunner -CommandInfo $installed[0] `
            -Description 'installed local Codex CLI'
    }

    if ($ExplicitCommand) {
        throw "The explicitly selected Codex command '$ExplicitCommand' is not available."
    }

    $npxCandidates = @(Get-Command 'npx' -All -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandType -eq [Management.Automation.CommandTypes]::Application })
    $npx = if ($env:OS -eq 'Windows_NT') {
        @($npxCandidates | Where-Object { [IO.Path]::GetExtension([string]$_.Source) -ieq '.cmd' } |
            Select-Object -First 1)
    }
    else {
        @($npxCandidates | Select-Object -First 1)
    }
    if ($npx.Count -eq 1) {
        return New-ExternalProcessRunner -CommandInfo $npx[0] `
            -PrefixArguments @('-y', "@openai/codex@$FallbackVersion") `
            -Description "temporary @openai/codex@$FallbackVersion through npx"
    }

    throw 'Codex CLI is not installed and npx is unavailable for the pinned temporary fallback.'
}

function Invoke-BoundedProcess {
    param(
        [Parameter(Mandatory)]$Runner,
        [Parameter(Mandatory)][string[]]$Arguments,
        [AllowEmptyString()][string]$StandardInput = '',
        [Parameter(Mandatory)][ValidateRange(1, 2147483647)][int]$TimeoutMilliseconds,
        [Parameter(Mandatory)][string]$TimeoutDescription,
        [Parameter(Mandatory)][string]$Operation
    )

    $allArguments = @($Runner.PrefixArguments) + @($Arguments)
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = [string]$Runner.Command
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $argumentListProperty = $startInfo.GetType().GetProperty('ArgumentList')
    if ($null -ne $argumentListProperty) {
        $nativeArgumentList = $argumentListProperty.GetValue($startInfo, $null)
        foreach ($argument in $allArguments) {
            [void]$nativeArgumentList.Add([string]$argument)
        }
    }
    else {
        $startInfo.Arguments = (@($allArguments | ForEach-Object {
            ConvertTo-ProcessArgument -Value ([string]$_)
        }) -join ' ')
    }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) {
            throw "Unable to start $Operation."
        }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if ($StandardInput) {
            $process.StandardInput.Write($StandardInput)
        }
        $process.StandardInput.Close()
        if (-not $process.WaitForExit($TimeoutMilliseconds)) {
            try {
                $process.Kill($true)
            }
            catch {
                if (-not $process.HasExited) {
                    if ($env:OS -eq 'Windows_NT') {
                        try {
                            & "$env:SystemRoot\System32\taskkill.exe" `
                                /PID $process.Id /T /F 2>&1 | Out-Null
                        }
                        catch { }
                    }
                    else {
                        try { $process.Kill() } catch { }
                    }
                }
            }
            [void]$process.WaitForExit(5000)
            throw "$Operation exceeded the $TimeoutDescription limit and was terminated."
        }
        $process.WaitForExit()
        return [pscustomobject]@{
            ExitCode = [int]$process.ExitCode
            StdOut = [string]$stdoutTask.GetAwaiter().GetResult()
            StdErr = [string]$stderrTask.GetAwaiter().GetResult()
        }
    }
    finally {
        $process.Dispose()
    }
}

function Get-ProcessFailureDetail {
    param([Parameter(Mandatory)]$Result)

    $detail = (@($Result.StdOut, $Result.StdErr) -join [Environment]::NewLine).Trim()
    if ($detail.Length -gt 1200) {
        $detail = $detail.Substring(0, 1200) + '...'
    }
    return $detail
}

function Assert-LocalCodexLogin {
    param(
        [Parameter(Mandatory)]$Runner,
        [Parameter(Mandatory)][int]$TimeoutMilliseconds,
        [Parameter(Mandatory)][string]$TimeoutDescription
    )

    $result = Invoke-BoundedProcess -Runner $Runner -Arguments @('login', 'status') `
        -TimeoutMilliseconds $TimeoutMilliseconds `
        -TimeoutDescription $TimeoutDescription `
        -Operation 'Local Codex authentication check'
    if ($result.ExitCode -ne 0) {
        $detail = Get-ProcessFailureDetail -Result $result
        throw "Local Codex authentication check failed with code $($result.ExitCode). $detail"
    }
}

function Invoke-LocalCodexExec {
    param(
        [Parameter(Mandatory)]$Runner,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)][int]$TimeoutMilliseconds,
        [Parameter(Mandatory)][string]$TimeoutDescription
    )

    # codex exec receives the scoped prompt through stdin and is bounded by the launcher.
    $arguments = @(
        'exec',
        '--ephemeral',
        '--ignore-user-config',
        '--sandbox', 'workspace-write',
        '--config', 'approval_policy="never"',
        '--config', 'sandbox_workspace_write.network_access=false',
        '--config', 'shell_environment_policy.inherit="core"',
        '--cd', $WorkingDirectory,
        '--output-last-message', $OutputPath,
        '-'
    )

    $result = Invoke-BoundedProcess -Runner $Runner -Arguments $arguments `
        -StandardInput $Prompt -TimeoutMilliseconds $TimeoutMilliseconds `
        -TimeoutDescription $TimeoutDescription `
        -Operation 'Local Codex adoption execution'
    if ($result.ExitCode -ne 0) {
        $detail = Get-ProcessFailureDetail -Result $result
        throw "Local Codex exited with code $($result.ExitCode). $detail"
    }
}

function Get-ProtocolSourceSnapshot {
    param(
        [string]$Token = '',
        [Parameter(Mandatory)][string]$Commit,
        [Parameter(Mandatory)][string]$Destination
    )

    if ($Commit -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The adoption manifest contains an invalid protocol commit.'
    }
    $sourceRoot = $null
    if ($Token) {
        $archivePath = Join-Path $Destination 'protocol-source.zip'
        $extractPath = Join-Path $Destination 'protocol-source'
        [IO.Directory]::CreateDirectory($extractPath) | Out-Null
        $headers = @{
            Accept = 'application/vnd.github+json'
            Authorization = "Bearer $Token"
            'X-GitHub-Api-Version' = '2026-03-10'
            'User-Agent' = 'meAndAI-quick-adoption'
        }
        $uri = "https://api.github.com/repos/$ProtocolRepository/zipball/$Commit"
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $uri -Headers $headers -OutFile $archivePath
            Expand-Archive -LiteralPath $archivePath -DestinationPath $extractPath -Force
        }
        catch {
            throw 'Unable to download the exact protocol source snapshot required for semantic adoption.'
        }

        $roots = @(Get-ChildItem -LiteralPath $extractPath -Directory)
        if ($roots.Count -eq 1) {
            $sourceRoot = $roots[0].FullName
        }
    }
    else {
        $sourceRoot = Join-Path $Destination 'protocol-source'
        try {
            Invoke-External -Command 'gh' -Arguments @(
                'repo', 'clone', $ProtocolRepository, $sourceRoot, '--',
                '--branch', $ProtocolTag, '--single-branch', '--depth', '1'
            ) | Out-Null
            $resolvedCommit = ((@(Invoke-Git -Repository $sourceRoot -Arguments @(
                'rev-parse', 'HEAD'
            )).Output -join '').Trim())
        }
        catch {
            throw 'Unable to clone the exact protocol source snapshot through the authenticated local GitHub CLI.'
        }
        if ($resolvedCommit -cne $Commit) {
            throw 'The authenticated protocol source snapshot does not match the adoption manifest commit.'
        }
    }

    if (-not $sourceRoot -or
        -not (Test-Path -LiteralPath (Join-Path $sourceRoot 'PROTOCOL.md') -PathType Leaf)) {
        throw 'The exact protocol source snapshot has an unexpected structure.'
    }
    $versionPath = Join-Path $sourceRoot 'VERSION'
    if (-not (Test-Path -LiteralPath $versionPath -PathType Leaf) -or
        [IO.File]::ReadAllText($versionPath).Trim() -cne $ProtocolTag.Substring(1)) {
        throw 'The protocol source snapshot version does not match the requested tag.'
    }
    return $sourceRoot
}

function Assert-CredentialFilesAbsent {
    param([Parameter(Mandatory)][string]$Repository)

    $files = @(Get-ChildItem -LiteralPath $Repository -Recurse -Force -File)
    foreach ($name in $tokenMappings.Keys) {
        $matches = @($files | Where-Object {
            ([string]$_.Name).Equals($name, [StringComparison]::OrdinalIgnoreCase)
        })
        if ($matches.Count -gt 0) {
            throw "Credential file '$name' must not exist in the isolated Codex clone."
        }
    }
}

function Assert-AdoptionProtocolReference {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$ProtocolSha
    )

    $protocolIndex = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'ls-files', '--stage', '--', '.ai/protocol'
    )).Output -join '').Trim())
    $expectedProtocolIndex = "160000 $ProtocolSha 0`t.ai/protocol"
    if ($protocolIndex -cne $expectedProtocolIndex) {
        throw 'The completed protocol reference is not the exact manifest gitlink.'
    }

    $gitmodulesPath = Join-Path $Repository '.gitmodules'
    $protocolModulePath = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'config', '-f', $gitmodulesPath, '--get', 'submodule..ai/protocol.path'
    )).Output -join '').Trim())
    $protocolModuleUrl = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'config', '-f', $gitmodulesPath, '--get', 'submodule..ai/protocol.url'
    )).Output -join '').Trim())
    if ($protocolModulePath -cne '.ai/protocol' -or
        $protocolModuleUrl -cne "https://github.com/$ProtocolRepository.git") {
        throw 'The completed protocol submodule metadata is not canonical.'
    }
}

function Get-ValidatedAdoptionManifest {
    param(
        [Parameter(Mandatory)][string]$ManifestPath,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ProposalRepository,
        [Parameter(Mandatory)][string]$ProposalHead,
        [Parameter(Mandatory)][string]$CanonicalBaseHead
    )

    try {
        $manifest = [IO.File]::ReadAllText($ManifestPath) | ConvertFrom-Json
    }
    catch {
        throw 'The adoption manifest is not valid JSON.'
    }
    if ([string]$PullRequest.meAndAIMarker.protocolSha -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The adoption manifest does not match the pull-request ownership marker.'
    }

    $modulePath = Join-Path $ProtocolSource `
        'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        throw 'The exact protocol source is missing its capabilities contract module.'
    }
    $modules = @(Import-Module -Name $modulePath -Force -PassThru)
    if ($modules.Count -ne 1) {
        throw 'The exact protocol capabilities contract module could not be loaded unambiguously.'
    }
    $module = $modules[0]
    try {
        $validators = @(Get-Command -Name 'Test-MeAndAIExactAdoptionManifest' `
            -Module ([string]$module.Name) -CommandType Function -ErrorAction SilentlyContinue)
        $resolvers = @(Get-Command -Name 'Resolve-MeAndAICapabilitiesLifecycle' `
            -Module ([string]$module.Name) -CommandType Function -ErrorAction SilentlyContinue)
        $targetPathGetters = @(Get-Command -Name 'Get-MeAndAIAdoptionTargetPaths' `
            -Module ([string]$module.Name) -CommandType Function -ErrorAction SilentlyContinue)
        if ($validators.Count -ne 1 -or $resolvers.Count -ne 1 -or
            $targetPathGetters.Count -ne 1) {
            throw 'The exact protocol capabilities contract does not export one path getter, resolver, and manifest validator.'
        }
        $targetPathGetter = $targetPathGetters[0]
        $targetPaths = @(& $targetPathGetter)
        $contract = Get-ExpectedAdoptionManifestContract `
            -Repository $ProposalRepository -ProposalHead $ProposalHead `
            -TargetPaths $targetPaths
        if ($null -eq $workflowBytes) {
            throw 'The independently verified canonical seed workflow bytes are unavailable.'
        }
        $sourceWorkflowSha = Get-GitBlobSha -Bytes ([byte[]]$workflowBytes)
        $baseWorkflowEntry = Get-AdoptionTreeEntry -Repository $ProposalRepository `
            -Commit ([string]$contract.BaseHead) -Path $workflowTargetPath
        $seedWorkflowState = if ($baseWorkflowEntry.Mode -ceq '100644' -and
            $baseWorkflowEntry.Type -ceq 'blob' -and
            $baseWorkflowEntry.Sha -ceq $sourceWorkflowSha) {
            'Exact'
        }
        elseif (-not $baseWorkflowEntry.Path) { 'Missing' }
        else { 'Drifted' }
        $resolver = $resolvers[0]
        $plan = & $resolver -Snapshot ([pscustomobject]@{
            SchemaVersion = 1
            LocalUpdaterState = [string]$contract.LocalUpdaterState
            SeedWorkflowState = $seedWorkflowState
            Collisions = @($contract.Collisions)
            ManifestExists = $false
            RemoteBranchExists = $false
            OpenPullRequestCount = 0
            ExistingProposalValid = $false
        })
        if ($null -eq $plan -or
            [string]$plan.State -cnotin @('BootstrapReady', 'AdoptionReviewRequired') -or
            [string]$PullRequest.meAndAIMarker.state -cne [string]$plan.State) {
            throw 'The adoption proposal is not permitted by the independently derived lifecycle contract.'
        }
        $validator = $validators[0]
        $valid = & $validator -Manifest $manifest -Repository $Repository `
            -TargetTag $ProtocolTag `
            -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha) `
            -ExpectedState ([string]$plan.State) `
            -ExpectedCollisions @($contract.Collisions)
    }
    finally {
        Remove-Module -Name ([string]$module.Name) -Force -ErrorAction SilentlyContinue
    }
    if ($valid -isnot [bool] -or -not $valid) {
        throw 'The adoption manifest does not exactly match the independently derived protocol contract.'
    }
    Assert-ExactAdoptionProposal -Repository $ProposalRepository `
        -ProposalHead $ProposalHead -CanonicalBaseHead $CanonicalBaseHead `
        -ProposalMode ([string]$plan.ProposalMode) -TargetPaths $targetPaths `
        -ProtocolSource $ProtocolSource `
        -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha)
    return $manifest
}

function Get-ValidatedAdoptionChangeSet {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$Manifest
    )

    Assert-CredentialFilesAbsent -Repository $Repository
    Invoke-Git -Repository $Repository -Arguments @('diff', '--check') | Out-Null
    Invoke-Git -Repository $Repository -Arguments @(
        'add', '-A', '--', '.', ':(exclude).ai/protocol'
    ) | Out-Null
    $changedPaths = @((Invoke-Git -Repository $Repository -Arguments @(
        'diff', '--cached', '--name-only', '--diff-filter=ACMRTD'
    )).Output | Where-Object { $_ })
    if ($changedPaths.Count -eq 0) {
        throw 'Local Codex produced no reviewable adoption change.'
    }
    foreach ($forbiddenPath in @($workflowTargetPath) + @($tokenMappings.Keys)) {
        $protectedDiff = Invoke-Git -Repository $Repository -Arguments @(
            'diff', '--cached', '--quiet', '--exit-code', '--', $forbiddenPath
        ) -AllowFailure
        if ($protectedDiff.ExitCode -eq 1) {
            throw "Local Codex changed protected adoption path '$forbiddenPath'."
        }
        if ($protectedDiff.ExitCode -ne 0) {
            throw "Protected adoption path '$forbiddenPath' could not be validated."
        }
    }
    if (@($changedPaths | Where-Object { $_ -clike '.ai/protocol/*' }).Count -gt 0) {
        throw 'Local Codex changed files inside the protocol reference instead of preserving one gitlink.'
    }
    Assert-AdoptionProtocolReference -Repository $Repository `
        -ProtocolSha ([string]$Manifest.protocolSha)
    Invoke-Git -Repository $Repository -Arguments @('diff', '--cached', '--check') | Out-Null
    return $changedPaths
}

function Assert-RecoverablePublishedAdoption {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$PreviousHead,
        [Parameter(Mandatory)][string]$PlannedHead,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [Parameter(Mandatory)][string]$ProtocolSource
    )

    $head = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'rev-parse', 'HEAD'
    )).Output -join '').Trim())
    if ($head -cne $PlannedHead -or
        (Get-SingleCommitParent -Repository $Repository -Commit $PlannedHead) -cne $PreviousHead) {
        throw 'The published adoption recovery commit does not match its persisted transition.'
    }
    $status = @((Invoke-Git -Repository $Repository -Arguments @(
        'status', '--porcelain=v1', '--untracked-files=all'
    )).Output | Where-Object { $_ })
    if ($status.Count -ne 0) {
        throw 'The published adoption recovery clone is not clean.'
    }
    Assert-CredentialFilesAbsent -Repository $Repository
    $manifestPath = Join-Path $Repository `
        ($adoptionManifestPath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (Test-Path -LiteralPath $manifestPath) {
        throw 'The published adoption recovery commit still contains the transient manifest.'
    }
    Invoke-Git -Repository $Repository -Arguments @(
        'diff', '--check', $PreviousHead, $PlannedHead, '--'
    ) | Out-Null
    $changedPaths = @((Invoke-Git -Repository $Repository -Arguments @(
        'diff', '--no-renames', '--name-only', '--diff-filter=ACMRTD',
        $PreviousHead, $PlannedHead, '--'
    )).Output | Where-Object { $_ })
    if ($changedPaths.Count -eq 0) {
        throw 'The published adoption recovery commit contains no reviewable change.'
    }
    foreach ($path in @($workflowTargetPath) + @($tokenMappings.Keys)) {
        if ($changedPaths -ccontains $path) {
            throw "The published adoption recovery commit changed protected path '$path'."
        }
    }
    if (@($changedPaths | Where-Object { $_ -clike '.ai/protocol/*' }).Count -gt 0) {
        throw 'The published adoption recovery commit changed content inside the protocol gitlink.'
    }
    Assert-AdoptionProtocolReference -Repository $Repository -ProtocolSha $ProtocolSha
    Assert-AdoptionUpdaterAssetsExact -Repository $Repository `
        -ProtocolSource $ProtocolSource -ProtocolSha $ProtocolSha -Commit $PlannedHead
}

function Get-RemoteBranchHead {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Remote,
        [Parameter(Mandatory)][string]$Branch,
        [switch]$AllowMissing
    )

    $result = Invoke-Git -Repository $Repository -Arguments @(
        'ls-remote', '--heads', $Remote, "refs/heads/$Branch"
    )
    $lines = @($result.Output | Where-Object { $_ })
    if ($AllowMissing -and $lines.Count -eq 0) {
        return $null
    }
    if ($lines.Count -ne 1) {
        throw 'The deterministic adoption branch is missing or ambiguous on the remote.'
    }
    $parts = ([string]$lines[0]).Split("`t")
    if ($parts.Count -ne 2 -or $parts[0] -cnotmatch '^[0-9a-f]{40}$' -or
        $parts[1] -cne "refs/heads/$Branch") {
        throw 'The deterministic adoption branch returned invalid remote metadata.'
    }
    return $parts[0]
}

function Invoke-AdoptionCodexCompletion {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ClonePath,
        [Parameter(Mandatory)][string]$TemporaryRoot,
        [Parameter(Mandatory)]$AdoptionIssue
    )

    $runner = Resolve-LocalCodexRunner -ExplicitCommand $CodexCommand `
        -FallbackVersion $TemporaryCodexVersion
    $timeoutMilliseconds = if ($CodexTimeoutSeconds -gt 0) {
        [int][Math]::Min(
            [int]::MaxValue, [TimeSpan]::FromSeconds($CodexTimeoutSeconds).TotalMilliseconds
        )
    }
    else {
        [int][Math]::Min(
            [int]::MaxValue, [TimeSpan]::FromMinutes($CodexTimeoutMinutes).TotalMilliseconds
        )
    }
    $timeoutDescription = if ($CodexTimeoutSeconds -gt 0) {
        "$CodexTimeoutSeconds second(s)"
    }
    else { "$CodexTimeoutMinutes minute(s)" }
    Assert-LocalCodexLogin -Runner $runner `
        -TimeoutMilliseconds $timeoutMilliseconds `
        -TimeoutDescription $timeoutDescription
    $resultPath = Join-Path $TemporaryRoot 'codex-result.txt'
    $prompt = @"
Complete the meAndAI AI-capabilities adoption for $Repository pull request #$($PullRequest.number) in this isolated temporary clone.

Read the manifest at .ai/adoption/meandai-capabilities.json, the exact protocol source at $ProtocolSource, every applicable AGENTS.md, and the consumer's existing project files before editing. Resolve collisions semantically; create or reconcile the project-owned feature and decision records, local memory, tests, evidence, and clickable links required by the protocol. The launcher already reconciled the required Agile labels and project-owned adoption issue $($AdoptionIssue.url); reference that issue from the local feature record. Do not invent project facts; if required facts are unavailable, stop as blocked. If the .ai/protocol gitlink is absent, create it from $ProtocolRepository at exactly $($Manifest.protocolSha); never substitute a moving ref.

Secret provisioning is already complete: FG_PAT.txt maps to MEANDAI_UPDATER_TOKEN and MEANDAI_RO_FG_PAT.txt maps to MEANDAI_PROTOCOL_TOKEN. Those source files are intentionally absent. Do not search for, request, print, recreate, or modify credential values or repository secrets.

Work only in this clone. Spawned-command network access is disabled: do not invoke gh, GitHub APIs, remote Git operations, or any other external service. Preserve any existing pinned protocol gitlink and do not change the lifecycle workflow. Do not commit, push, approve, mark the pull request ready, merge, close, delete, or alter branches. The launcher owns GitHub records and Git publication; the maintainer owns merge.

Keep validation bounded: implement reviewable slices, run relevant tests, perform one fresh-diff self-review and the protocol's bounded completion scan, fix blocking findings only, and avoid recursive validators. Remove .ai/adoption/meandai-capabilities.json only when all adoption gates are satisfied.

Your final response must start with MEANDAI_ADOPTION_READY only when the manifest has been removed and the repository-local adoption work is complete. Otherwise start with MEANDAI_ADOPTION_BLOCKED and state the exact blocker. Include concise test evidence.
"@
    Invoke-LocalCodexExec -Runner $runner -WorkingDirectory $ClonePath `
        -Prompt $prompt -OutputPath $resultPath `
        -TimeoutMilliseconds $timeoutMilliseconds `
        -TimeoutDescription $timeoutDescription
    if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
        throw 'Local Codex completed without a final result file.'
    }
    $result = [IO.File]::ReadAllText($resultPath).Trim()
    if (-not $result.StartsWith('MEANDAI_ADOPTION_READY', [StringComparison]::Ordinal)) {
        if ($result.Length -gt 1200) { $result = $result.Substring(0, 1200) + '...' }
        throw "Local Codex did not declare the adoption ready. $result"
    }
    return [pscustomobject]@{ Runner = $runner; Result = $result }
}

function Complete-AdoptionWithLocalCodex {
    param(
        [Parameter(Mandatory)][string]$TargetRepository,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$CanonicalBaseHead,
        [string]$ProtocolToken = ''
    )

    $branch = [string]$PullRequest.headRefName
    $expectedHead = [string]$PullRequest.headRefOid
    $expectedBody = [string]$PullRequest.body
    $localBaseHead = ((@(Invoke-Git -Repository $TargetRepository -Arguments @(
        'rev-parse', 'HEAD'
    )).Output -join '').Trim())
    $remoteBaseHead = Get-RemoteBranchHead -Repository $TargetRepository `
        -Remote $RemoteName -Branch ([string]$PullRequest.baseRefName)
    if ($CanonicalBaseHead -cnotmatch '^[0-9a-f]{40}$' -or
        $localBaseHead -cne $CanonicalBaseHead -or
        $remoteBaseHead -cne $CanonicalBaseHead) {
        throw 'The canonical consumer base changed before local adoption validation.'
    }
    $remoteHead = Get-RemoteBranchHead -Repository $TargetRepository -Remote $RemoteName -Branch $branch
    if ($remoteHead -cne $expectedHead) {
        throw 'The pull-request head and live adoption branch differ before local execution.'
    }

    $temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) `
        "meandai-local-adoption-$([guid]::NewGuid().ToString('N'))"
    $clonePath = Join-Path $temporaryRoot 'consumer'
    [IO.Directory]::CreateDirectory($temporaryRoot) | Out-Null
    try {
        $remoteUrl = ((@(Invoke-Git -Repository $TargetRepository -Arguments @(
            'remote', 'get-url', $RemoteName
        )).Output -join '').Trim())
        Invoke-External -Command 'git' -Arguments @(
            'clone', '--no-tags', '--single-branch', '--branch', $branch,
            $remoteUrl, $clonePath
        ) | Out-Null

        $cloneHead = ((@(Invoke-Git -Repository $clonePath -Arguments @(
            'rev-parse', 'HEAD'
        )).Output -join '').Trim())
        if ($cloneHead -cne $expectedHead) {
            throw 'The isolated clone did not resolve to the expected pull-request head.'
        }
        Assert-CredentialFilesAbsent -Repository $clonePath

        $manifestPath = Join-Path $clonePath `
            ($adoptionManifestPath -replace '/', [IO.Path]::DirectorySeparatorChar)
        $protocolSource = $null
        if ([string]$PullRequest.meAndAIMarker.phase -ceq 'Publishing') {
            $previousHead = [string]$PullRequest.meAndAIMarker.previousHead
            $plannedHead = [string]$PullRequest.meAndAIMarker.plannedHead
            $protocolSource = Get-ProtocolSourceSnapshot -Token $ProtocolToken `
                -Commit ([string]$PullRequest.meAndAIMarker.protocolSha) `
                -Destination $temporaryRoot
            if ($expectedHead -ceq $plannedHead) {
                Assert-RecoverablePublishedAdoption -Repository $clonePath `
                    -PreviousHead $previousHead -PlannedHead $plannedHead `
                    -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha) `
                    -ProtocolSource $protocolSource
                Ensure-AdoptionLabels -Repository $Repository
                $adoptionIssue = Ensure-AdoptionIssue -Repository $Repository `
                    -PullRequest $PullRequest -TemporaryDirectory $temporaryRoot
                [void](Complete-AdoptionReviewTransition -Repository $Repository `
                    -PullRequest $PullRequest -PublishedHead $plannedHead `
                    -ExpectedMarkerHead $previousHead -TemporaryDirectory $temporaryRoot `
                    -Issue $adoptionIssue -PersistCompletedMarker)
                return [pscustomobject]@{
                    Ran = $false
                    Pushed = $false
                    Ready = $true
                    RequiresManualReview = $false
                    Runner = 'publishing recovery'
                    Head = $plannedHead
                }
            }
            if ($expectedHead -cne $previousHead) {
                throw 'The publishing adoption branch matches neither persisted transition head.'
            }
            if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
                throw 'The unpushed publishing transition cannot be restored because its proposal manifest is missing.'
            }
            $restoredBody = Set-AdoptionPullRequestProposedMarker `
                -Repository $Repository -PullRequest $PullRequest `
                -PreviousHead $previousHead -TemporaryDirectory $temporaryRoot
            $PullRequest = Get-RevalidatedAdoptionPullRequest -Repository $Repository `
                -OriginalPullRequest $PullRequest -LiveHead $previousHead `
                -MarkerHead $previousHead -Body $restoredBody -Draft $true
            $expectedBody = $restoredBody
        }
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            if ([string]$PullRequest.meAndAIMarker.phase -ceq 'Completed') {
                if ($null -eq $protocolSource) {
                    $protocolSource = Get-ProtocolSourceSnapshot -Token $ProtocolToken `
                        -Commit ([string]$PullRequest.meAndAIMarker.protocolSha) `
                        -Destination $temporaryRoot
                }
                $proposalHead = Get-SingleCommitParent -Repository $clonePath `
                    -Commit $expectedHead
                $proposalManifestText = @((Invoke-Git -Repository $clonePath `
                    -Arguments @('show', "${proposalHead}:$adoptionManifestPath")).Output) `
                    -join [Environment]::NewLine
                if ([string]::IsNullOrWhiteSpace($proposalManifestText)) {
                    throw 'The completed adoption parent does not contain its proposal manifest.'
                }
                $proposalManifestPath = Join-Path $temporaryRoot `
                    'completed-proposal-manifest.json'
                [IO.File]::WriteAllText(
                    $proposalManifestPath,
                    $proposalManifestText,
                    [Text.UTF8Encoding]::new($false)
                )
                [void](Get-ValidatedAdoptionManifest `
                    -ManifestPath $proposalManifestPath -Repository $Repository `
                    -PullRequest $PullRequest -ProtocolSource $protocolSource `
                    -ProposalRepository $clonePath -ProposalHead $proposalHead `
                    -CanonicalBaseHead $CanonicalBaseHead)
                Assert-RecoverablePublishedAdoption -Repository $clonePath `
                    -PreviousHead $proposalHead -PlannedHead $expectedHead `
                    -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha) `
                    -ProtocolSource $protocolSource
                Ensure-AdoptionLabels -Repository $Repository
                $adoptionIssue = Ensure-AdoptionIssue -Repository $Repository `
                    -PullRequest $PullRequest -TemporaryDirectory $temporaryRoot
                [void](Complete-AdoptionReviewTransition -Repository $Repository `
                    -PullRequest $PullRequest -PublishedHead $expectedHead `
                    -ExpectedMarkerHead $expectedHead -TemporaryDirectory $temporaryRoot `
                    -Issue $adoptionIssue)
                return [pscustomobject]@{
                    Ran = $false
                    Pushed = $false
                    Ready = $true
                    RequiresManualReview = $false
                    Runner = 'not required'
                    Head = $expectedHead
                }
            }
            Assert-AdoptionProtocolReference -Repository $clonePath `
                -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha)
            return [pscustomobject]@{
                Ran = $false
                Pushed = $false
                Ready = -not [bool]$PullRequest.isDraft
                RequiresManualReview = [bool]$PullRequest.isDraft
                Runner = 'not required'
            }
        }
        if (-not [bool]$PullRequest.isDraft) {
            throw 'The adoption manifest remains but the pull request is no longer a draft.'
        }
        if ([string]$PullRequest.meAndAIMarker.phase -cne 'Proposed') {
            throw 'The adoption manifest remains after the proposal entered a completed phase.'
        }

        if ($null -eq $protocolSource) {
            $protocolSource = Get-ProtocolSourceSnapshot -Token $ProtocolToken `
                -Commit ([string]$PullRequest.meAndAIMarker.protocolSha) `
                -Destination $temporaryRoot
        }
        $manifest = Get-ValidatedAdoptionManifest -ManifestPath $manifestPath `
            -Repository $Repository -PullRequest $PullRequest `
            -ProtocolSource $protocolSource -ProposalRepository $clonePath `
            -ProposalHead $expectedHead -CanonicalBaseHead $CanonicalBaseHead
        if ([string]$manifest.state -ceq 'BootstrapReady') {
            Assert-AdoptionProtocolReference -Repository $clonePath `
                -ProtocolSha ([string]$manifest.protocolSha)
        }

        Ensure-AdoptionLabels -Repository $Repository
        $adoptionIssue = Ensure-AdoptionIssue -Repository $Repository `
            -PullRequest $PullRequest -TemporaryDirectory $temporaryRoot

        $codexCompletion = Invoke-AdoptionCodexCompletion -Repository $Repository `
            -PullRequest $PullRequest -Manifest $manifest -ProtocolSource $protocolSource `
            -ClonePath $clonePath -TemporaryRoot $temporaryRoot -AdoptionIssue $adoptionIssue
        $runner = $codexCompletion.Runner
        $result = [string]$codexCompletion.Result

        $headAfterCodex = ((@(Invoke-Git -Repository $clonePath -Arguments @(
            'rev-parse', 'HEAD'
        )).Output -join '').Trim())
        if ($headAfterCodex -cne $expectedHead) {
            throw 'Local Codex created a commit; the launcher will not publish an agent-owned history.'
        }
        if (Test-Path -LiteralPath $manifestPath) {
            throw 'Local Codex declared readiness but left the transient adoption manifest.'
        }
        Get-ValidatedAdoptionChangeSet -Repository $clonePath -Manifest $manifest | Out-Null
        Assert-AdoptionUpdaterAssetsExact -Repository $clonePath `
            -ProtocolSource $protocolSource -ProtocolSha ([string]$manifest.protocolSha) `
            -UseIndex

        $liveHead = Get-RemoteBranchHead -Repository $clonePath -Remote 'origin' -Branch $branch
        if ($liveHead -cne $expectedHead) {
            throw 'The adoption branch changed while local Codex was running; no local result was published.'
        }
        [void](Get-RevalidatedAdoptionPullRequest -Repository $Repository `
            -OriginalPullRequest $PullRequest -LiveHead $expectedHead `
            -MarkerHead $expectedHead -Body $expectedBody -Draft $true)

        $targetName = ((@(Invoke-Git -Repository $TargetRepository -Arguments @(
            'config', 'user.name'
        )).Output -join '').Trim())
        $targetEmail = ((@(Invoke-Git -Repository $TargetRepository -Arguments @(
            'config', 'user.email'
        )).Output -join '').Trim())
        Invoke-Git -Repository $clonePath -Arguments @('config', 'user.name', $targetName) | Out-Null
        Invoke-Git -Repository $clonePath -Arguments @('config', 'user.email', $targetEmail) | Out-Null
        Invoke-Git -Repository $clonePath -Arguments @(
            'commit', '-m', "Complete meAndAI AI capabilities adoption for $ProtocolTag"
        ) | Out-Null
        $publishedHead = ((@(Invoke-Git -Repository $clonePath -Arguments @(
            'rev-parse', 'HEAD'
        )).Output -join '').Trim())
        if ((Get-SingleCommitParent -Repository $clonePath -Commit $publishedHead) -cne $expectedHead) {
            throw 'The completed adoption commit does not have the exact proposal parent.'
        }
        Assert-AdoptionUpdaterAssetsExact -Repository $clonePath `
            -ProtocolSource $protocolSource -ProtocolSha ([string]$manifest.protocolSha) `
            -Commit $publishedHead
        [void](Get-RevalidatedAdoptionPullRequest -Repository $Repository `
            -OriginalPullRequest $PullRequest -LiveHead $expectedHead `
            -MarkerHead $expectedHead -Body $expectedBody -Draft $true)
        $publishingBody = Set-AdoptionPullRequestPublishingMarker `
            -Repository $Repository -PullRequest $PullRequest `
            -PreviousHead $expectedHead -PlannedHead $publishedHead `
            -TemporaryDirectory $temporaryRoot
        $publishingPullRequest = Get-RevalidatedAdoptionPullRequest `
            -Repository $Repository -OriginalPullRequest $PullRequest `
            -LiveHead $expectedHead -MarkerHead $expectedHead `
            -Body $publishingBody -Draft $true
        Invoke-Git -Repository $clonePath -Arguments @(
            'push', 'origin',
            "--force-with-lease=refs/heads/$branch`:$expectedHead",
            "HEAD:refs/heads/$branch"
        ) | Out-Null
        $verifiedHead = Get-RemoteBranchHead -Repository $clonePath -Remote 'origin' -Branch $branch
        if ($verifiedHead -cne $publishedHead) {
            throw 'The adoption branch did not resolve to the launcher-published commit.'
        }

        [void](Complete-AdoptionReviewTransition -Repository $Repository `
            -PullRequest $publishingPullRequest -PublishedHead $publishedHead `
            -ExpectedMarkerHead $expectedHead -TemporaryDirectory $temporaryRoot `
            -Issue $adoptionIssue -PersistCompletedMarker)
        return [pscustomobject]@{
            Ran = $true
            Pushed = $true
            Ready = $true
            Runner = $runner.Description
            Head = $publishedHead
            Result = $result
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryRoot) {
            Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

foreach ($command in @('git', 'gh')) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        throw "Required command '$command' is not available."
    }
}

$target = Get-NormalizedPath -Path $TargetPath
if (-not (Test-Path -LiteralPath $target -PathType Container)) {
    throw "TargetPath must identify an existing directory: $target"
}

Invoke-External -Command 'gh' -Arguments @('auth', 'status') | Out-Null

$inside = Invoke-Git -Repository $target -Arguments @('rev-parse', '--is-inside-work-tree') -AllowFailure
if ($inside.ExitCode -eq 0 -and ((@($inside.Output) -join '').Trim() -eq 'true')) {
    $rootResult = Invoke-Git -Repository $target -Arguments @('rev-parse', '--show-toplevel')
    $gitRoot = Get-NormalizedPath -Path ((@($rootResult.Output) -join '').Trim())
    if (-not $gitRoot.Equals($target, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'TargetPath is nested inside another Git repository; select that repository root explicitly.'
    }
}
else {
    Invoke-External -Command 'git' -Arguments @('init', '-b', 'main', $target) | Out-Null
}

Add-LocalTokenExcludes -Repository $target

$headResult = Invoke-Git -Repository $target -Arguments @('rev-parse', '--verify', 'HEAD') -AllowFailure
$hasHead = $headResult.ExitCode -eq 0
$remoteResult = Invoke-Git -Repository $target -Arguments @(
    'config', '--get', "remote.$RemoteName.url"
) -AllowFailure
$hasRemote = $remoteResult.ExitCode -eq 0
$remoteSlug = ''
$remoteIsEmpty = $false

if ($hasRemote) {
    $remoteUrl = ((@($remoteResult.Output) -join '').Trim())
    $remoteSlug = Get-GitHubSlugFromRemote -RemoteUrl $remoteUrl
    $remoteHeads = Invoke-Git -Repository $target -Arguments @(
        'ls-remote', '--heads', $RemoteName
    )
    $remoteIsEmpty = -not ((@($remoteHeads.Output) -join '').Trim())
}

$requiredTokenFiles = if ($hasRemote) {
    @()
}
else {
    @($tokenMappings.Keys)
}
Assert-TokenFilesAreLocalOnly -Repository $target -RequiredFileNames $requiredTokenFiles

if (-not $hasRemote -and $hasHead) {
    throw "A repository with commits but no '$RemoteName' is outside the safe new-repository flow. Connect and reconcile it manually."
}
if ($hasRemote -and -not $remoteIsEmpty -and -not $hasHead) {
    throw 'The connected remote contains history but the local repository has no commit; clone or reconcile it manually.'
}

if ($hasRemote -and $remoteIsEmpty -and $hasHead) {
    $commitCount = ((@(Invoke-Git -Repository $target -Arguments @(
        'rev-list', '--count', 'HEAD'
    )).Output -join '').Trim())
    $treePaths = @((Invoke-Git -Repository $target -Arguments @(
        'ls-tree', '-r', '--name-only', 'HEAD'
    )).Output | Where-Object { $_ })
    if ($commitCount -cne '1' -or $treePaths.Count -ne 1 -or
        $treePaths[0] -cne $workflowTargetPath) {
        throw 'An empty remote may resume only the launcher-owned, single seed-only local commit.'
    }
}

$resumableNewRepository = (-not $hasRemote -and -not $hasHead) -or
    ($hasRemote -and $remoteIsEmpty)
if ($resumableNewRepository) {
    $stagedBefore = Invoke-Git -Repository $target -Arguments @('diff', '--cached', '--name-only') -AllowFailure
    $stagedPaths = @($stagedBefore.Output | Where-Object { $_ })
    if ($stagedPaths.Count -gt 1 -or
        ($stagedPaths.Count -eq 1 -and $stagedPaths[0] -cne $workflowTargetPath)) {
        throw 'The resumable new-repository flow permits only the exact seed workflow in the Git index.'
    }
    if ($hasHead) {
        $resumeBranch = ((@(Invoke-Git -Repository $target -Arguments @(
            'branch', '--show-current'
        )).Output -join '').Trim())
        if ($resumeBranch -cne 'main') {
            throw "The resumable unpublished seed must remain on 'main'."
        }
    }
    else {
        Invoke-Git -Repository $target -Arguments @('branch', '-M', 'main') | Out-Null
    }
}
else {
    $status = Invoke-Git -Repository $target -Arguments @(
        'status', '--porcelain=v1', '--untracked-files=all'
    )
    foreach ($line in @($status.Output)) {
        if (-not $line) {
            continue
        }
        if ($line.Length -lt 4 -or $line.Substring(3) -cne $workflowTargetPath) {
            throw 'The connected repository must be clean apart from the exact seed workflow candidate.'
        }
    }
}

$protocolToken = $null
$workflowBytes = $null
if (-not $hasRemote) {
    $protocolToken = Read-LocalToken -Path (Join-Path $target 'MEANDAI_RO_FG_PAT.txt')
    $workflowBytes = Get-CanonicalWorkflow -ProtocolToken $protocolToken
}

if ($hasRemote) {
    $view = Invoke-External -Command 'gh' -Arguments @(
        'repo', 'view', $remoteSlug, '--json', 'nameWithOwner,defaultBranchRef'
    )
    try {
        $repositoryInfo = ((@($view.Output) -join [Environment]::NewLine) | ConvertFrom-Json)
    }
    catch {
        throw 'GitHub CLI returned invalid repository metadata.'
    }
    $repository = [string]$repositoryInfo.nameWithOwner
    $defaultBranch = if ($null -ne $repositoryInfo.defaultBranchRef) {
        [string]$repositoryInfo.defaultBranchRef.name
    }
    else {
        ''
    }
    if (-not $repository.Equals($remoteSlug, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Remote '$RemoteName' identity does not match GitHub repository metadata."
    }
    if (-not $remoteIsEmpty -and -not $defaultBranch) {
        throw 'The connected GitHub repository has no default branch.'
    }
    if ($remoteIsEmpty) {
        $defaultBranch = 'main'
    }
    if ($Owner -and -not $repository.StartsWith("$Owner/", [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The explicit Owner does not match the connected repository.'
    }
    if ($RepositoryName -and
        -not $repository.EndsWith("/$RepositoryName", [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The explicit RepositoryName does not match the connected repository.'
    }

    $branch = ((@(Invoke-Git -Repository $target -Arguments @(
        'branch', '--show-current'
    )).Output -join '').Trim())
    if ($branch -cne $defaultBranch) {
        throw "The current branch '$branch' is not the GitHub default branch '$defaultBranch'."
    }
    if (-not $remoteIsEmpty) {
        Invoke-Git -Repository $target -Arguments @('fetch', '--quiet', $RemoteName, $defaultBranch) | Out-Null
        $localHead = ((@($headResult.Output) -join '').Trim())
        $remoteHead = ((@(Invoke-Git -Repository $target -Arguments @(
            'rev-parse', "$RemoteName/$defaultBranch"
        )).Output -join '').Trim())
        if ($localHead -cne $remoteHead) {
            throw 'The local and remote default-branch heads differ; reconcile them before adoption.'
        }
    }
}
else {
    if (-not $Owner) {
        $ownerResult = Invoke-External -Command 'gh' -Arguments @('api', 'user', '--jq', '.login')
        $Owner = ((@($ownerResult.Output) -join '').Trim())
    }
    if (-not $RepositoryName) {
        $RepositoryName = Split-Path -Leaf $target
    }
    if ($Owner -cnotmatch '^[A-Za-z0-9_.-]+$' -or
        $RepositoryName -cnotmatch '^[A-Za-z0-9_.-]+$' -or
        $RepositoryName -in @('.', '..')) {
        throw 'Owner and RepositoryName must be valid unambiguous GitHub slugs.'
    }
    $repository = "$Owner/$RepositoryName"
    $defaultBranch = 'main'

    $visibilityArgument = switch ($Visibility) {
        'private' { '--private' }
        'public' { '--public' }
        'internal' { '--internal' }
    }
    Invoke-External -Command 'gh' -Arguments @(
        'repo', 'create', $repository, $visibilityArgument,
        '--source', $target, '--remote', $RemoteName
    ) | Out-Null
    $createdRemoteUrl = ((@(Invoke-Git -Repository $target -Arguments @(
        'config', '--get', "remote.$RemoteName.url"
    )).Output -join '').Trim())
    $createdSlug = Get-GitHubSlugFromRemote -RemoteUrl $createdRemoteUrl
    if (-not $createdSlug.Equals($repository, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The created remote identity does not match the requested GitHub repository.'
    }
    $remoteIsEmpty = $true
}

$repositoryOwner = $repository.Split('/')[0]
$nameResult = Invoke-Git -Repository $target -Arguments @('config', 'user.name') -AllowFailure
if ($nameResult.ExitCode -ne 0 -or -not ((@($nameResult.Output) -join '').Trim())) {
    Invoke-Git -Repository $target -Arguments @('config', 'user.name', $repositoryOwner) | Out-Null
}
$emailResult = Invoke-Git -Repository $target -Arguments @('config', 'user.email') -AllowFailure
if ($emailResult.ExitCode -ne 0 -or -not ((@($emailResult.Output) -join '').Trim())) {
    Invoke-Git -Repository $target -Arguments @(
        'config', 'user.email', "$repositoryOwner@users.noreply.github.com"
    ) | Out-Null
}

$protocolTokenPath = Join-Path $target 'MEANDAI_RO_FG_PAT.txt'
$protocolTokenFileExists = Test-Path -LiteralPath $protocolTokenPath -PathType Leaf
if ($null -eq $workflowBytes) {
    # Executable source authority is verified before the temporary lock label
    # performs the first repository mutation. Prefer the local read-only token
    # when its verified file is present; otherwise use the authenticated gh
    # identity without attempting to recover an existing Actions secret.
    if ($protocolTokenFileExists) {
        $protocolToken = Read-LocalToken -Path $protocolTokenPath
        $workflowBytes = Get-CanonicalWorkflow -ProtocolToken $protocolToken
    }
    else {
        $workflowBytes = Get-CanonicalWorkflow
    }
}

$workflowFullPath = Assert-ContainedManagedDestination `
    -Root $target -RelativePath $workflowTargetPath
if (Test-Path -LiteralPath $workflowFullPath) {
    if (-not (Test-Path -LiteralPath $workflowFullPath -PathType Leaf)) {
        throw "The existing seed workflow path '$workflowTargetPath' is not a regular file."
    }
    $existingWorkflowBytes = [IO.File]::ReadAllBytes($workflowFullPath)
    if (-not (Test-ByteArrayEqual -Left $existingWorkflowBytes -Right $workflowBytes)) {
        throw "The existing seed workflow '$workflowTargetPath' differs from the canonical $ProtocolTag bytes; repository secrets were not inspected or changed."
    }
}

$secretLock = Enter-RepositorySecretReconciliationLock -Repository $repository
$secretOperationError = $null
$secretLockCleanupError = $null
try {
    # The name inventory and every missing-secret write share one GitHub-wide
    # critical section. A competing host cannot act on the same stale snapshot.
    $existingSecretNames = @(Get-RepositorySecretNames -Repository $repository)
    $protocolSecretMissing = $existingSecretNames -notcontains 'MEANDAI_PROTOCOL_TOKEN'
    if ($protocolSecretMissing -and -not $protocolTokenFileExists) {
        throw "Required local credential file 'MEANDAI_RO_FG_PAT.txt' is missing because repository Actions secret 'MEANDAI_PROTOCOL_TOKEN' does not exist."
    }
    if ($null -eq $protocolToken -and $protocolTokenFileExists) {
        $protocolToken = Read-LocalToken -Path $protocolTokenPath
    }

    $updaterSecretMissing = $existingSecretNames -notcontains 'MEANDAI_UPDATER_TOKEN'
    $updaterToken = $null
    if ($updaterSecretMissing) {
        $updaterTokenPath = Join-Path $target 'FG_PAT.txt'
        if (-not (Test-Path -LiteralPath $updaterTokenPath -PathType Leaf)) {
            throw "Required local credential file 'FG_PAT.txt' is missing because repository Actions secret 'MEANDAI_UPDATER_TOKEN' does not exist."
        }
        $updaterToken = Read-LocalToken -Path $updaterTokenPath
        try {
            $targetInfo = Invoke-GitHubApi -Uri "https://api.github.com/repos/$repository" -Token $updaterToken
            if (-not ([string]$targetInfo.full_name).Equals($repository, [StringComparison]::OrdinalIgnoreCase)) {
                throw 'identity mismatch'
            }
        }
        catch {
            throw "The updater token cannot access '$repository'. Add this repository to the token's selected-repository grant, then rerun."
        }
    }

    foreach ($entry in $tokenMappings.GetEnumerator()) {
        if ($existingSecretNames -contains $entry.Value) {
            Write-Host "Repository Actions secret '$($entry.Value)' already exists and was preserved."
            continue
        }
        $value = if ($entry.Key -ceq 'FG_PAT.txt') { $updaterToken } else { $protocolToken }
        Set-RepositorySecret -Repository $repository -Name $entry.Value -Value $value
    }
}
catch {
    $secretOperationError = $_.Exception
}
finally {
    try {
        Exit-RepositorySecretReconciliationLock -Repository $repository -Lock $secretLock
    }
    catch {
        $secretLockCleanupError = $_.Exception
    }
}
if ($null -ne $secretOperationError) {
    if ($null -ne $secretLockCleanupError) {
        throw "$($secretOperationError.Message) Secret-lock cleanup also failed: $($secretLockCleanupError.Message)"
    }
    throw $secretOperationError
}
if ($null -ne $secretLockCleanupError) {
    throw $secretLockCleanupError
}

[void](Write-CanonicalWorkflow -Path $workflowFullPath -Bytes $workflowBytes)

Invoke-Git -Repository $target -Arguments @('add', '--', $workflowTargetPath) | Out-Null
$staged = @((Invoke-Git -Repository $target -Arguments @(
    'diff', '--cached', '--name-only', '--diff-filter=ACMRT'
)).Output | Where-Object { $_ })
if ($staged.Count -gt 1 -or ($staged.Count -eq 1 -and $staged[0] -cne $workflowTargetPath)) {
    throw 'The staged change set is not exactly the canonical seed workflow.'
}

$createdCommit = $false
if ($staged.Count -eq 1) {
    $nameResult = Invoke-Git -Repository $target -Arguments @('config', 'user.name') -AllowFailure
    $emailResult = Invoke-Git -Repository $target -Arguments @('config', 'user.email') -AllowFailure
    if ($nameResult.ExitCode -ne 0 -or $emailResult.ExitCode -ne 0 -or
        -not ((@($nameResult.Output) -join '').Trim()) -or
        -not ((@($emailResult.Output) -join '').Trim())) {
        throw 'Git user.name and user.email are required before the seed can be committed.'
    }
    Invoke-Git -Repository $target -Arguments @(
        'commit', '-m', 'Adopt meAndAI AI capabilities lifecycle'
    ) | Out-Null
    $createdCommit = $true
}

if ($createdCommit -or $remoteIsEmpty) {
    Invoke-Git -Repository $target -Arguments @(
        'push', '-u', $RemoteName, $defaultBranch
    ) | Out-Null
}

Write-Host "meAndAI quick adoption seed is ready in $repository at $ProtocolTag."
Write-Host 'Repository Actions secrets were reconciled by preserving existing names and creating only missing names.'

if ($SkipLifecycleDispatch) {
    Write-Host 'Lifecycle dispatch was explicitly skipped. Run the meAndAI AI capabilities lifecycle workflow before adoption.'
}
else {
    $publishedHead = ((@(Invoke-Git -Repository $target -Arguments @(
        'rev-parse', 'HEAD'
    )).Output -join '').Trim())
    $actorResult = Invoke-External -Command 'gh' -Arguments @('api', 'user', '--jq', '.login')
    $authenticatedActor = ((@($actorResult.Output) -join '').Trim())
    if ($authenticatedActor -cnotmatch '^[A-Za-z0-9_.-]+$') {
        throw 'The authenticated GitHub maintainer identity is invalid.'
    }
    $adoptionBranch = "automation/meandai-capabilities-$ProtocolTag"
    $existingAdoptionHead = Get-RemoteBranchHead -Repository $target `
        -Remote $RemoteName -Branch $adoptionBranch -AllowMissing
    $preExistingPullRequest = if ($existingAdoptionHead) {
        Get-AdoptionPullRequest -Repository $repository -BaseBranch $defaultBranch `
            -ExpectedActor $authenticatedActor -MaxAttempts 1
    }
    else { $null }
    if ($null -ne $preExistingPullRequest -and
        [string]$preExistingPullRequest.meAndAIMarker.phase -cin @('Publishing', 'Completed')) {
        $adoptionPullRequestResults = @($preExistingPullRequest)
        Write-Host 'A launcher-owned completion transition already exists; lifecycle dispatch was not repeated.'
    }
    else {
        $run = Invoke-LifecycleWorkflow -Repository $repository -Branch $defaultBranch -HeadSha $publishedHead
        Write-Host "Lifecycle workflow completed successfully: $($run.url)"
        $adoptionPullRequestResults = @(Get-AdoptionPullRequest -Repository $repository `
            -BaseBranch $defaultBranch -ExpectedActor $authenticatedActor)
    }
    if ($adoptionPullRequestResults.Count -gt 1) {
        $types = @($adoptionPullRequestResults | ForEach-Object { $_.GetType().FullName }) -join ', '
        throw "Adoption pull-request resolution returned ambiguous results: $types"
    }
    $adoptionPullRequest = if ($adoptionPullRequestResults.Count -eq 1) {
        $adoptionPullRequestResults[0]
    }
    else {
        $null
    }
    if ($null -eq $adoptionPullRequest) {
        Write-Host 'No open deterministic adoption draft was produced; inspect the successful lifecycle run before continuing.'
    }
    else {
        if ($null -eq $adoptionPullRequest.PSObject.Properties['url']) {
            $propertyNames = @($adoptionPullRequest.PSObject.Properties | ForEach-Object { $_.Name }) -join ', '
            throw "Resolved adoption pull-request metadata has unexpected properties: $propertyNames"
        }
        Write-Host "Adoption draft: $($adoptionPullRequest.url)"
        if ($SkipLocalCodex) {
            Write-Host 'Local Codex execution was explicitly skipped; use the quick-guide prompt in an isolated checkout of this draft.'
        }
        else {
            $completion = Complete-AdoptionWithLocalCodex -TargetRepository $target `
                -Repository $repository -PullRequest $adoptionPullRequest `
                -CanonicalBaseHead $publishedHead -ProtocolToken $protocolToken
            if ($completion.Ran) {
                Write-Host "Local Codex completed synchronously through $($completion.Runner)."
                Write-Host "The validated adoption commit was pushed and the pull request is ready: $($adoptionPullRequest.url)"
            }
            else {
                Write-Host 'The adoption manifest was already absent; local Codex was not run again.'
                if ($completion.Ready) {
                    Write-Host "The pull request was already ready for the maintainer's final review: $($adoptionPullRequest.url)"
                }
                else {
                    Write-Host "The draft was not changed because prior manifest removal has no launcher-owned validation evidence; review it and mark it ready manually: $($adoptionPullRequest.url)"
                }
            }
        }
    }
}

Write-Host 'The launcher never approves or merges the adoption pull request; the maintainer owns the final merge.'
