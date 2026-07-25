# Mechanically extracted from the reviewed v0.12.4 quick-adoption launcher.
function ConvertTo-MeAndAIGitHubTimestamp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowNull()][object]$Value
    )

    if ($Value -is [DateTimeOffset]) {
        return ([DateTimeOffset]$Value).ToUniversalTime()
    }
    if ($Value -is [DateTime]) {
        $dateTime = [DateTime]$Value
        if ($dateTime.Kind -eq [DateTimeKind]::Unspecified) {
            throw 'GitHub timestamp has no timezone identity.'
        }
        return ([DateTimeOffset]$dateTime).ToUniversalTime()
    }
    if ($Value -isnot [string] -or
        [string]::IsNullOrWhiteSpace([string]$Value)) {
        throw 'GitHub timestamp has an unsupported representation.'
    }

    $formats = [string[]]@(
        "yyyy-MM-dd'T'HH:mm:ss'Z'",
        "yyyy-MM-dd'T'HH:mm:ss.FFFFFFF'Z'",
        "yyyy-MM-dd'T'HH:mm:sszzz",
        "yyyy-MM-dd'T'HH:mm:ss.FFFFFFFzzz"
    )
    $styles = [Globalization.DateTimeStyles]::AssumeUniversal -bor
        [Globalization.DateTimeStyles]::AdjustToUniversal
    $parsed = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParseExact(
            [string]$Value,
            $formats,
            [Globalization.CultureInfo]::InvariantCulture,
            $styles,
            [ref]$parsed
        )) {
        throw 'GitHub timestamp is not an exact RFC 3339 value.'
    }
    return $parsed.ToUniversalTime()
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
    param([Parameter(Mandatory)][string]$Repository)

    # HEAD may be unborn while another branch, tag, or reflog remains locally
    # reachable. History completeness and credential-path evidence therefore
    # cannot be conditional on the currently checked-out branch having a commit.
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

    foreach ($name in $tokenMappings.Keys) {
        # Recursive glob plus icase catches the protected basename at the root
        # or any depth, including case variants on case-sensitive Git indexes.
        $credentialPathspec = ":(icase,glob)**/$name"
        $tracked = Invoke-Git -Repository $Repository -Arguments @(
            'ls-files', '--error-unmatch', '--', $credentialPathspec
        ) -AllowFailure
        if ($tracked.ExitCode -eq 0) {
            throw "Credential-shaped file '$name' is tracked or staged. Remove every case/path variant from Git, rotate that token, and rerun."
        }

        $history = Invoke-Git -Repository $Repository -Arguments @(
            'log', '--all', '--reflog', '--format=%H', '--',
            $credentialPathspec
        ) -AllowFailure
        if ($history.ExitCode -ne 0) {
            throw "Credential history for '$name' could not be inspected."
        }
        if ((@($history.Output) -join '').Trim()) {
            throw "Credential-shaped file '$name' appears in locally reachable ref or reflog history. Rotate that token and clean every case/path variant from history before rerunning."
        }

    }
}

function Assert-LocalCredentialRegularFile {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Name
    )

    if (@($tokenMappings.Keys | Where-Object { [string]$_ -ceq $Name }).Count -ne 1) {
        throw "Credential file name '$Name' is not one canonical launcher input."
    }
    $path = Assert-ContainedManagedDestination -Root $Root -RelativePath $Name
    $item = Get-Item -LiteralPath $path -Force -ErrorAction Stop
    $linkTypeProperty = $item.PSObject.Properties['LinkType']
    $isLink = $null -ne $linkTypeProperty -and
        -not [string]::IsNullOrEmpty([string]$linkTypeProperty.Value)
    $isReparsePoint = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
    if ($item.PSIsContainer -or $isLink -or $isReparsePoint -or
        $item.Name -cne $Name -or
        -not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Credential path '$Name' must be one exact root regular non-link file."
    }
    return $path
}

function Read-LocalToken {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Name
    )

    $path = Assert-LocalCredentialRegularFile -Root $Root -Name $Name
    $value = [IO.File]::ReadAllText($path).Trim()
    [void](Assert-LocalCredentialRegularFile -Root $Root -Name $Name)
    if (-not $value -or $value -match '\s') {
        throw "Credential file '$Name' must contain exactly one non-whitespace token value."
    }
    return $value
}

function Read-ProtocolTokenForInitialPolicy {
    param([Parameter(Mandatory)][string]$Root)

    $tokenPath = Join-Path $Root 'MEANDAI_RO_FG_PAT.txt'
    if (-not (Test-Path -LiteralPath $tokenPath -PathType Leaf)) {
        return ''
    }
    $inside = Invoke-Git -Repository $Root `
        -Arguments @('rev-parse', '--is-inside-work-tree') -AllowFailure
    if ($inside.ExitCode -eq 0 -and
        ((@($inside.Output) -join '').Trim() -ceq 'true')) {
        $rootResult = Invoke-Git -Repository $Root `
            -Arguments @('rev-parse', '--show-toplevel')
        $gitRoot = Get-NormalizedPath `
            -Path ((@($rootResult.Output) -join '').Trim())
        if (-not $gitRoot.Equals($Root, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'TargetPath is nested inside another Git repository; select that repository root explicitly.'
        }
        Assert-TokenFilesAreLocalOnly -Repository $Root
    }
    elseif (Test-Path -LiteralPath (Join-Path $Root '.git')) {
        throw 'The local Git repository identity could not be verified before reading the protocol token.'
    }
    return Read-LocalToken -Root $Root -Name 'MEANDAI_RO_FG_PAT.txt'
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
    param(
        [string]$ProtocolToken = '',
        [string]$Tag = $ProtocolTag
    )

    if ($Tag -cnotmatch '^v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)$') {
        throw "Protocol tag '$Tag' must use the canonical vM.m.rev form."
    }
    if ($script:ValidatedProtocolReleases.ContainsKey($Tag)) {
        return $script:ValidatedProtocolReleases[$Tag]
    }

    $escapedTag = [Uri]::EscapeDataString($Tag)
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
            throw "Unable to verify the published immutable GitHub Release '$Tag' through the authenticated local GitHub CLI."
        }
    }

    $requiredProperties = @('tag_name', 'draft', 'prerelease', 'immutable', 'published_at')
    foreach ($property in $requiredProperties) {
        if ($null -eq $release -or $null -eq $release.PSObject.Properties[$property]) {
            throw "The published immutable GitHub Release response is missing '$property'."
        }
    }
    try {
        $publishedAt = ConvertTo-MeAndAIGitHubTimestamp `
            -Value $release.published_at
    }
    catch {
        throw "Protocol source '$Tag' is not an exact published immutable GitHub Release."
    }
    if ([string]$release.tag_name -cne $Tag -or
        $release.draft -isnot [bool] -or $release.draft -or
        $release.prerelease -isnot [bool] -or $release.prerelease -or
        $release.immutable -isnot [bool] -or -not $release.immutable) {
        throw "Protocol source '$Tag' is not an exact published immutable GitHub Release."
    }

    $commitEndpoint = "repos/$ProtocolRepository/commits/$escapedTag"
    if ($ProtocolToken) {
        $commit = Invoke-GitHubApi `
            -Uri "https://api.github.com/$commitEndpoint" -Token $ProtocolToken
    }
    else {
        try {
            $commitResult = Invoke-External -Command 'gh' -Arguments @(
                'api',
                '-H', 'Accept: application/vnd.github+json',
                '-H', 'X-GitHub-Api-Version: 2026-03-10',
                $commitEndpoint
            )
            $commit = ((@($commitResult.Output) -join [Environment]::NewLine) |
                ConvertFrom-Json)
        }
        catch {
            throw "Unable to resolve immutable protocol release '$Tag' to one commit through the authenticated local GitHub CLI."
        }
    }
    if ($null -eq $commit -or $null -eq $commit.PSObject.Properties['sha'] -or
        [string]$commit.sha -cnotmatch '^[0-9a-f]{40}$') {
        throw "Immutable protocol release '$Tag' did not resolve to one canonical commit."
    }

    $evidence = [pscustomobject]@{
        Tag = $Tag
        CommitSha = [string]$commit.sha
        Release = $release
    }
    $script:ValidatedProtocolReleases.Add($Tag, $evidence)
    return $evidence
}

function Get-CanonicalProtocolAsset {
    param(
        [Parameter(Mandatory)][string]$Tag,
        [Parameter(Mandatory)][string]$TemplatePath,
        [string]$ProtocolToken = ''
    )

    if ($ProtocolRepository -cnotmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        throw "ProtocolRepository '$ProtocolRepository' must use the owner/repository form."
    }
    if ($TemplatePath -cnotmatch '^[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*$') {
        throw "Protocol asset path '$TemplatePath' is not canonical."
    }

    [void](Get-ValidatedImmutableProtocolRelease `
        -ProtocolToken $ProtocolToken -Tag $Tag)
    $cacheKey = "$Tag`n$TemplatePath"
    if ($script:CanonicalProtocolAssets.ContainsKey($cacheKey)) {
        return $script:CanonicalProtocolAssets[$cacheKey]
    }

    $escapedRef = [Uri]::EscapeDataString($Tag)
    $uri = "https://api.github.com/repos/$ProtocolRepository/contents/$TemplatePath`?ref=$escapedRef"
    if ($ProtocolToken) {
        $response = Invoke-GitHubApi -Uri $uri -Token $ProtocolToken
    }
    else {
        $endpoint = "repos/$ProtocolRepository/contents/$TemplatePath`?ref=$escapedRef"
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
            throw "Unable to retrieve canonical protocol asset '$TemplatePath' at '$Tag' through the authenticated local GitHub CLI. Verify local gh access to '$ProtocolRepository', then rerun."
        }
    }
    if ($response.encoding -cne 'base64' -or -not $response.content -or -not $response.sha) {
        throw "Canonical protocol asset '$TemplatePath' is incomplete or uses an unsupported encoding."
    }

    try {
        $bytes = [Convert]::FromBase64String(([string]$response.content))
    }
    catch {
        throw "Canonical protocol asset '$TemplatePath' contains invalid base64 content."
    }
    $actualSha = & $script:GetQuickAdoptionGitBlobSha1 -Bytes $bytes
    if ($actualSha -cne ([string]$response.sha).ToLowerInvariant()) {
        throw "Canonical protocol asset '$TemplatePath' failed Git blob verification."
    }
    $asset = [pscustomobject]@{
        Tag = $Tag
        TemplatePath = $TemplatePath
        Bytes = [byte[]]$bytes
        Sha = $actualSha
    }
    $script:CanonicalProtocolAssets.Add($cacheKey, $asset)
    return $asset
}

function Get-CanonicalWorkflow {
    param([string]$ProtocolToken = '')

    $asset = Get-CanonicalProtocolAsset -Tag $ProtocolTag `
        -TemplatePath $workflowSourcePath -ProtocolToken $ProtocolToken
    return [byte[]]$asset.Bytes
}

function Test-CanonicalWorkflowSupportsSourceGraphIdentity {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $decoder = [Text.UTF8Encoding]::new($false, $true)
    try { $source = $decoder.GetString($Bytes) }
    catch {
        throw 'The exact canonical workflow is not valid UTF-8 text.'
    }
    $declarations = [regex]::Matches(
        $source,
        '(?m)^ {6}source_graph_identity:[ \t]*\r?$'
    )
    if ($declarations.Count -gt 1) {
        throw 'The exact canonical workflow declares ambiguous source-graph identity inputs.'
    }
    return $declarations.Count -eq 1
}

function Import-CanonicalInitialAdoptionPolicy {
    param([string]$ProtocolToken = '')

    $asset = Get-CanonicalProtocolAsset -Tag $initialAdoptionPolicyTag `
        -TemplatePath $initialAdoptionPolicySourcePath `
        -ProtocolToken $ProtocolToken
    $decoder = [Text.UTF8Encoding]::new($false, $true)
    try {
        $source = $decoder.GetString([byte[]]$asset.Bytes)
        $scriptBlock = [scriptblock]::Create($source)
    }
    catch {
        throw 'The exact initial-adoption policy module is not valid UTF-8 PowerShell source.'
    }

    $moduleName = "MeAndAI.InitialAdoptionPolicy.$($asset.Sha).$([guid]::NewGuid().ToString('N'))"
    $dynamicModule = New-Module -Name $moduleName -ScriptBlock $scriptBlock
    $loaded = @()
    try {
        $loaded = @(Import-Module -ModuleInfo $dynamicModule -Force -PassThru)
        if ($loaded.Count -ne 1) {
            throw 'The exact initial-adoption policy module could not be loaded unambiguously.'
        }
        $requiredCommands = @(
            'Assert-MeAndAIProtocolAssessmentPathCasing',
            'ConvertTo-MeAndAIInstructionGraphRecord',
            'Get-MeAndAIInstructionGraphIdentity',
            'Get-MeAndAIInstructionGraphLimits',
            'Get-MeAndAILinkedPathIdentityDigest',
            'Get-MeAndAIProtocolAssessmentLimits',
            'Get-MeAndAIProtocolSurfaceInventory',
            'New-MeAndAIGitHubBlobLink',
            'New-MeAndAIInstructionGraph',
            'Resolve-MeAndAIAdoptionStrategy',
            'Resolve-MeAndAIInstructionGraphClosure',
            'Test-MeAndAICompletedAdoptionChangeSet',
            'Test-MeAndAICanonicalRepositoryPath',
            'Test-MeAndAIConsumerGovernancePath',
            'Test-MeAndAIExactAdoptionPullRequestMarker',
            'Test-MeAndAIExactLinkedPathSection',
            'Test-MeAndAIExactInstructionGraph',
            'Test-MeAndAIExactInstructionGraphIdentity',
            'Test-MeAndAIExactInstructionGraphIdentityRecord',
            'Test-MeAndAILegacyCommonAuthorityPath',
            'Test-MeAndAILegacyGovernancePath',
            'Test-MeAndAIProtocolAssessmentRelevantPath',
            'Test-MeAndAIReservedProtocolSubmoduleContract'
        )
        $commands = [System.Collections.Generic.Dictionary[string, object]]::new(
            [StringComparer]::Ordinal
        )
        foreach ($name in $requiredCommands) {
            $command = $loaded[0].ExportedCommands[$name]
            if ($null -eq $command -or [string]$command.ModuleName -cne $moduleName) {
                throw "The exact initial-adoption policy module does not export '$name'."
            }
            $commands.Add($name, $command)
        }
        $limits = & $commands['Get-MeAndAIProtocolAssessmentLimits']
        $graphLimits = & $commands['Get-MeAndAIInstructionGraphLimits']
        if ($null -eq $limits -or $limits -is [array] -or
            $null -eq $limits.PSObject.Properties['MaximumSurfaceCount'] -or
            $null -eq $limits.PSObject.Properties['MaximumSurfaceUtf8Bytes'] -or
            [long]$limits.MaximumSurfaceCount -lt 1 -or
            [long]$limits.MaximumSurfaceCount -gt 65536 -or
            [long]$limits.MaximumSurfaceUtf8Bytes -lt 1 -or
            [long]$limits.MaximumSurfaceUtf8Bytes -gt 1048576) {
            throw 'The exact initial-adoption policy returned invalid assessment limits.'
        }
        if ($null -eq $graphLimits -or $graphLimits -is [array] -or
            [long]$graphLimits.MaximumTreeEntries -ne 65536 -or
            [long]$graphLimits.MaximumTreePathUtf8Bytes -ne 4194304 -or
            [long]$graphLimits.MaximumNodes -ne 512 -or
            [long]$graphLimits.MaximumEdges -ne 4096 -or
            [long]$graphLimits.MaximumDepth -ne 32 -or
            [long]$graphLimits.MaximumBlobBytes -ne 262144 -or
            [long]$graphLimits.MaximumAggregateBlobBytes -ne 4194304 -or
            [long]$graphLimits.MaximumPathUtf8Bytes -ne 16384) {
            throw 'The exact initial-adoption policy returned invalid instruction-graph limits.'
        }
        return [pscustomobject]@{
            Tag = $initialAdoptionPolicyTag
            BlobSha = [string]$asset.Sha
            Module = $loaded[0]
            Commands = $commands
            Limits = [pscustomobject]@{
                MaximumSurfaceCount = [int]$limits.MaximumSurfaceCount
                MaximumSurfaceUtf8Bytes = [int]$limits.MaximumSurfaceUtf8Bytes
                MaximumTreeEntries = [int]$graphLimits.MaximumTreeEntries
                MaximumTreePathUtf8Bytes =
                    [int]$graphLimits.MaximumTreePathUtf8Bytes
                MaximumNodes = [int]$graphLimits.MaximumNodes
                MaximumEdges = [int]$graphLimits.MaximumEdges
                MaximumDepth = [int]$graphLimits.MaximumDepth
                MaximumBlobBytes = [int]$graphLimits.MaximumBlobBytes
                MaximumAggregateBlobBytes =
                    [int]$graphLimits.MaximumAggregateBlobBytes
                MaximumPathUtf8Bytes =
                    [int]$graphLimits.MaximumPathUtf8Bytes
            }
        }
    }
    catch {
        foreach ($module in @($loaded) + @($dynamicModule)) {
            if ($null -ne $module) {
                Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
            }
        }
        throw
    }
}

function ConvertTo-CanonicalProtocolVersionRecord {
    param([Parameter(Mandatory)][string]$Tag)

    $match = [regex]::Match(
        $Tag,
        '^v(?<major>0|[1-9][0-9]*)\.(?<minor>0|[1-9][0-9]*)\.(?<revision>0|[1-9][0-9]*)$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if (-not $match.Success) {
        throw "Protocol tag '$Tag' must use the canonical vM.m.rev form."
    }
    return [pscustomobject]@{
        Tag = $Tag
        Parts = @(
            [string]$match.Groups['major'].Value,
            [string]$match.Groups['minor'].Value,
            [string]$match.Groups['revision'].Value
        )
    }
}

function Compare-CanonicalProtocolVersion {
    param(
        [Parameter(Mandatory)]$Left,
        [Parameter(Mandatory)]$Right
    )

    for ($index = 0; $index -lt 3; $index++) {
        $comparison = Compare-CanonicalDecimalComponent `
            -Left ([string]$Left.Parts[$index]) `
            -Right ([string]$Right.Parts[$index])
        if ($comparison -ne 0) {
            return $comparison
        }
    }
    return 0
}

function Assert-CanonicalProtocolSubmoduleMetadata {
    param([Parameter(Mandatory)][string]$Repository)

    $pathResult = Invoke-Git -Repository $Repository -Arguments @(
        'config', '-f', '.gitmodules', '--get-regexp', '^submodule\..*\.path$'
    ) -AllowFailure
    if ($pathResult.ExitCode -ne 0) {
        throw "Installed protocol metadata has no canonical '$('.ai/protocol')' entry."
    }
    $matches = @($pathResult.Output | Where-Object {
        [string]$_ -match '^submodule\.\.ai/protocol\.path\s+\.ai/protocol$'
    })
    if ($matches.Count -ne 1) {
        throw "Installed protocol metadata must contain one canonical '.ai/protocol' path entry."
    }
    $urlResult = Invoke-Git -Repository $Repository -Arguments @(
        'config', '-f', '.gitmodules', '--get-all', 'submodule..ai/protocol.url'
    ) -AllowFailure
    $urls = @($urlResult.Output | Where-Object { $_ })
    $expectedUrl = "https://github.com/$ProtocolRepository.git"
    if ($urlResult.ExitCode -ne 0 -or $urls.Count -ne 1 -or
        [string]$urls[0] -cne $expectedUrl) {
        throw "Installed protocol metadata must use canonical URL '$expectedUrl'."
    }
}

function Get-ExistingAdoptionRoute {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [string]$HeadSha = '',
        [string]$ProtocolToken = ''
    )

    if (-not $HeadSha) {
        return [pscustomobject]@{
            State = 'InitialAdoption'; InstalledTag = ''; InstalledProtocolSha = ''
        }
    }
    if ($HeadSha -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Existing adoption routing received an invalid default-branch head.'
    }

    $manifestEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $HeadSha -Path $adoptionManifestPath
    if ($manifestEntry.Path) {
        throw 'The transient adoption manifest exists on the default branch; managed routing is ambiguous.'
    }
    $protocolEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $HeadSha -Path '.ai/protocol'
    if (-not $protocolEntry.Path) {
        return [pscustomobject]@{
            State = 'InitialAdoption'; InstalledTag = ''; InstalledProtocolSha = ''
        }
    }
    if ($protocolEntry.Mode -cne '160000' -or
        $protocolEntry.Type -cne 'commit' -or
        $protocolEntry.Sha -cnotmatch '^[0-9a-f]{40}$') {
        return [pscustomobject]@{
            State = 'InitialAdoption'; InstalledTag = ''; InstalledProtocolSha = ''
        }
    }

    $workingChanges = @((Invoke-Git -Repository $Repository -Arguments @(
        'status', '--porcelain=v1', '--untracked-files=all'
    )).Output | Where-Object { $_ })
    if ($workingChanges.Count -ne 0) {
        throw 'A completed adoption must be clean before current/update routing.'
    }
    $gitmodulesEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $HeadSha -Path '.gitmodules'
    if ($gitmodulesEntry.Mode -cne '100644' -or $gitmodulesEntry.Type -cne 'blob') {
        throw "Installed protocol gitlink has no canonical '.gitmodules' blob."
    }
    Assert-CanonicalProtocolSubmoduleMetadata -Repository $Repository

    foreach ($asset in $managedUpdaterAssets) {
        $consumerEntry = Get-AdoptionTreeEntry -Repository $Repository `
            -Commit $HeadSha -Path ([string]$asset.ConsumerPath)
        if ($consumerEntry.Mode -cne '100644' -or $consumerEntry.Type -cne 'blob') {
            throw "Installed updater asset '$($asset.ConsumerPath)' is absent or partial."
        }
    }

    $workflowText = (@(Invoke-Git -Repository $Repository -Arguments @(
        'show', "${HeadSha}:$workflowTargetPath"
    )).Output -join "`n")
    $declarations = [regex]::Matches(
        $workflowText,
        '(?m)^[ \t]*BOOTSTRAP_PROTOCOL_TAG[ \t]*:.*$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    $canonicalDeclarations = [regex]::Matches(
        $workflowText,
        '(?m)^  BOOTSTRAP_PROTOCOL_TAG: (?<tag>v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*))$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if ($declarations.Count -ne 1 -or $canonicalDeclarations.Count -ne 1) {
        throw 'Installed updater workflow has no single canonical bootstrap protocol tag.'
    }
    $installedTag = [string]$canonicalDeclarations[0].Groups['tag'].Value
    $installedVersion = ConvertTo-CanonicalProtocolVersionRecord -Tag $installedTag
    $targetVersion = ConvertTo-CanonicalProtocolVersionRecord -Tag $ProtocolTag
    if ([string]$installedVersion.Parts[0] -cne [string]$targetVersion.Parts[0]) {
        throw "Installed protocol '$installedTag' and requested '$ProtocolTag' cross a major-version boundary; use a reviewed migration."
    }

    $installedRelease = Get-ValidatedImmutableProtocolRelease `
        -ProtocolToken $ProtocolToken -Tag $installedTag
    if ([string]$installedRelease.CommitSha -cne [string]$protocolEntry.Sha) {
        throw "Installed protocol gitlink does not match immutable release '$installedTag'."
    }
    foreach ($asset in $managedUpdaterAssets) {
        $sourceAsset = Get-CanonicalProtocolAsset -Tag $installedTag `
            -TemplatePath ([string]$asset.TemplatePath) `
            -ProtocolToken $ProtocolToken
        $consumerEntry = Get-AdoptionTreeEntry -Repository $Repository `
            -Commit $HeadSha -Path ([string]$asset.ConsumerPath)
        if ([string]$consumerEntry.Sha -cne [string]$sourceAsset.Sha) {
            throw "Installed updater asset '$($asset.ConsumerPath)' drifted from immutable release '$installedTag'."
        }
    }

    $comparison = Compare-CanonicalProtocolVersion `
        -Left $installedVersion -Right $targetVersion
    if ($comparison -gt 0) {
        throw "Installed protocol '$installedTag' is newer than requested launcher target '$ProtocolTag'; downgrade is prohibited."
    }
    return [pscustomobject]@{
        State = if ($comparison -eq 0) { 'AlreadyCurrent' } else { 'CompatibleUpdate' }
        InstalledTag = $installedTag
        InstalledProtocolSha = [string]$protocolEntry.Sha
    }
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
        if (-not (& $script:TestQuickAdoptionByteArrayEqual `
            -Left $current -Right $Bytes)) {
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
