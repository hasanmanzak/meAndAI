[CmdletBinding()]
param(
    [string]$ProtocolRepository = 'hasanmanzak/meAndAI',
    [string]$ProtocolPath = '.ai/protocol',
    [string]$ProtocolSourcePath = '.meandai-update-source',
    [string]$BranchPrefix = 'automation/meandai-protocol-',
    [switch]$FinalizeMergedPullRequest,
    [switch]$RecoverMergedPullRequests,
    [switch]$CurrentLauncher,
    [string]$RequestedTargetTag = '',
    [string]$RequestedTargetCommit = '',
    [string]$RequestedBaseSha = '',
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
$ConsumerMigrationModulePath = 'scripts/MeAndAI.ConsumerMigrations.psm1'
$ConsumerMigrationIndexPath = 'migrations/index.json'
$ConsumerMigrationLedgerPath = '.ai/meandai-update-state.json'
$MigrationBranchSuffix = '-migrations'
$RecoveryBranchSuffix = '-recovery'
$UpdateBranchSuffix = if ($CurrentLauncher) { $RecoveryBranchSuffix } else { '' }
$script:ConsumerMigrationPlansByTag = @{}
$script:CurrentLauncher = [bool]$CurrentLauncher
$ManagedUpdateLabels = @(
    [pscustomobject]@{ Name = 'type:task'; Color = 'd4c5f9'; Description = 'Implementation or maintenance task' },
    [pscustomobject]@{ Name = 'priority:p1'; Color = 'd93f0b'; Description = 'High priority' },
    [pscustomobject]@{ Name = 'status:in-progress'; Color = '1d76db'; Description = 'Implementation in progress' },
    [pscustomobject]@{ Name = 'status:needs-review'; Color = '5319e7'; Description = 'Ready for maintainer review' },
    [pscustomobject]@{ Name = 'status:blocked'; Color = 'b60205'; Description = 'Blocked by an unresolved dependency' }
)

function Invoke-Native {
    param(
        [string]$Command,
        [string[]]$Arguments,
        [int[]]$AcceptedExitCodes = @(0),
        [switch]$PassThruResult,
        [switch]$CaptureFailure
    )

    if ($CaptureFailure -and -not $PassThruResult) {
        throw 'CaptureFailure requires PassThruResult.'
    }

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $global:LASTEXITCODE = 0
        $output = @(& $Command @Arguments 2>&1)
        $exitCode = if ($null -eq $LASTEXITCODE) {
            0
        }
        else {
            [int]$LASTEXITCODE
        }
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if (-not ($AcceptedExitCodes -contains $exitCode) -and -not $CaptureFailure) {
        throw "$Command $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    if ($PassThruResult) {
        return [pscustomobject]@{
            ExitCode = [int]$exitCode
            Output = @($output)
        }
    }
    $output
}

function Get-GhReadFailureClassification {
    param(
        [int]$ExitCode,
        [object[]]$Output
    )

    if ($ExitCode -eq 0) { return 'Success' }
    $text = (@($Output | ForEach-Object { [string]$_ }) -join "`n")
    $statusMatches = [regex]::Matches(
        $text,
        '(?i)(?:HTTP(?:[ /]|\s+status\s+)?|status(?:\s+code)?[ =:]+)(?<code>[1-5][0-9]{2})',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    $statuses = @($statusMatches | ForEach-Object {
        [int]$_.Groups['code'].Value
    })
    if (@($statuses | Where-Object { $_ -cin @(401, 403, 404, 422) }).Count -ne 0) {
        return 'Permanent'
    }
    if (@($statuses | Where-Object {
        $_ -eq 408 -or $_ -eq 429 -or ($_ -ge 500 -and $_ -le 599)
    }).Count -ne 0) {
        return 'Retryable'
    }
    foreach ($signal in @(
        'connectex', 'connection attempt failed', 'context deadline exceeded',
        'client.timeout', 'timed out', 'timeout', 'connection reset',
        'forcibly closed', 'wsarecv', 'unexpected eof', 'dial tcp',
        'tls handshake timeout'
    )) {
        if ($text.IndexOf($signal, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return 'Retryable'
        }
    }
    return 'Permanent'
}

function Invoke-GhReadNative {
    param(
        [Parameter(Mandatory)][string]$Endpoint,
        [AllowNull()][string]$Token = $null,
        [switch]$Paginate
    )

    if ([string]::IsNullOrWhiteSpace($Endpoint) -or
        $Endpoint.StartsWith('-', [StringComparison]::Ordinal)) {
        throw 'GitHub API read requires one exact endpoint.'
    }
    $arguments = @(
        'api', '--method', 'GET',
        '-H', 'Accept: application/vnd.github+json',
        '-H', 'X-GitHub-Api-Version: 2026-03-10'
    )
    if ($Paginate) {
        $arguments += @('--paginate', '--jq', '.[] | @base64')
    }
    $arguments += $Endpoint
    $previousToken = [Environment]::GetEnvironmentVariable('GH_TOKEN', 'Process')
    try {
        if ($PSBoundParameters.ContainsKey('Token') -and
            -not [string]::IsNullOrEmpty($Token)) {
            [Environment]::SetEnvironmentVariable('GH_TOKEN', $Token, 'Process')
        }
        for ($attempt = 1; $attempt -le 3; $attempt++) {
            $result = Invoke-Native -Command 'gh' -Arguments $arguments `
                -PassThruResult -CaptureFailure
            if ([int]$result.ExitCode -eq 0) {
                return @($result.Output)
            }
            $classification = Get-GhReadFailureClassification `
                -ExitCode ([int]$result.ExitCode) -Output @($result.Output)
            if ($classification -cne 'Retryable' -or $attempt -eq 3) {
                $diagnostic = @($result.Output | ForEach-Object { [string]$_ }) `
                    -join [Environment]::NewLine
                throw "GitHub API GET '$Endpoint' failed on attempt $attempt of 3: $diagnostic"
            }
            Start-Sleep -Milliseconds $(if ($attempt -eq 1) { 250 } else { 500 })
        }
    }
    finally {
        if ($PSBoundParameters.ContainsKey('Token') -and
            -not [string]::IsNullOrEmpty($Token)) {
            [Environment]::SetEnvironmentVariable('GH_TOKEN', $previousToken, 'Process')
        }
    }
}

function Invoke-GhReadJson {
    param(
        [Parameter(Mandatory)][string]$Endpoint,
        [AllowNull()][string]$Token = $null
    )

    $output = if ($PSBoundParameters.ContainsKey('Token')) {
        @(Invoke-GhReadNative -Endpoint $Endpoint -Token $Token)
    }
    else { @(Invoke-GhReadNative -Endpoint $Endpoint) }
    $text = $output -join [Environment]::NewLine
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    try { return $text | ConvertFrom-Json }
    catch { throw "GitHub API GET '$Endpoint' returned invalid JSON." }
}

function Invoke-GhPagedReadJson {
    param(
        [Parameter(Mandatory)][string]$Endpoint,
        [AllowNull()][string]$Token = $null
    )

    $encodedItems = if ($PSBoundParameters.ContainsKey('Token')) {
        @(Invoke-GhReadNative -Endpoint $Endpoint -Token $Token -Paginate)
    }
    else { @(Invoke-GhReadNative -Endpoint $Endpoint -Paginate) }
    foreach ($encodedItem in $encodedItems) {
        try {
            $bytes = [Convert]::FromBase64String(([string]$encodedItem).Trim())
            $json = [Text.UTF8Encoding]::new($false, $true).GetString($bytes)
            $json | ConvertFrom-Json
        }
        catch { throw "GitHub API paged GET '$Endpoint' returned invalid JSON evidence." }
    }
}

function Test-GitAncestor {
    param(
        [string]$RepositoryPath,
        [string]$Ancestor,
        [string]$Descendant
    )

    $result = Invoke-Native -Command 'git' -Arguments @(
        '-C', $RepositoryPath, 'merge-base', '--is-ancestor',
        $Ancestor, $Descendant
    ) -AcceptedExitCodes @(0, 1) -PassThruResult
    return [int]$result.ExitCode -eq 0
}

function Invoke-GhJson {
    param(
        [string[]]$Arguments,
        [AllowNull()][string]$Token = $null
    )

    $previousToken = [Environment]::GetEnvironmentVariable('GH_TOKEN', 'Process')
    try {
        if ($PSBoundParameters.ContainsKey('Token') -and
            -not [string]::IsNullOrEmpty($Token)) {
            [Environment]::SetEnvironmentVariable('GH_TOKEN', $Token, 'Process')
        }
        $text = (Invoke-Native -Command 'gh' -Arguments $Arguments) -join [Environment]::NewLine
    }
    finally {
        if ($PSBoundParameters.ContainsKey('Token') -and
            -not [string]::IsNullOrEmpty($Token)) {
            [Environment]::SetEnvironmentVariable('GH_TOKEN', $previousToken, 'Process')
        }
    }
    if (-not $text) {
        return $null
    }
    $text | ConvertFrom-Json
}

function Invoke-GhMutationWithBodyFile {
    param(
        [Parameter(Mandatory)][ValidateSet('POST', 'PATCH')][string]$Method,
        [Parameter(Mandatory)][string]$Endpoint,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Body,
        [string[]]$Fields = @(),
        [AllowNull()][string]$Token = $null
    )

    $temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) `
        ('meandai-gh-body-' + [guid]::NewGuid().ToString('N'))
    try {
        [void](New-Item -ItemType Directory -Path $temporaryRoot)
        $bodyPath = Join-Path $temporaryRoot 'body.txt'
        [IO.File]::WriteAllText(
            $bodyPath, $Body, [Text.UTF8Encoding]::new($false)
        )
        $arguments = @('api', '--method', $Method, $Endpoint)
        foreach ($field in @($Fields)) {
            if ([string]::IsNullOrEmpty([string]$field) -or
                [string]$field -notmatch '^[^=\r\n]+=' -or
                ([string]$field).StartsWith(
                    'body=', [StringComparison]::OrdinalIgnoreCase
                )) {
                throw 'GitHub mutation contains an invalid non-body field.'
            }
            $arguments += @('-f', [string]$field)
        }
        $arguments += @('-F', "body=@$bodyPath")
        if ($PSBoundParameters.ContainsKey('Token')) {
            return Invoke-GhJson -Arguments $arguments -Token $Token
        }
        return Invoke-GhJson -Arguments $arguments
    }
    finally {
        if (Test-Path -LiteralPath $temporaryRoot) {
            Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
        }
    }
}

function Invoke-GhPullRequestCreateWithBodyFile {
    param(
        [Parameter(Mandatory)][string]$Base,
        [Parameter(Mandatory)][string]$Head,
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Body,
        [AllowNull()][string]$Token = $null
    )

    $temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) `
        ('meandai-gh-pr-body-' + [guid]::NewGuid().ToString('N'))
    $previousToken = [Environment]::GetEnvironmentVariable('GH_TOKEN', 'Process')
    try {
        [void](New-Item -ItemType Directory -Path $temporaryRoot)
        $bodyPath = Join-Path $temporaryRoot 'body.txt'
        [IO.File]::WriteAllText(
            $bodyPath, $Body, [Text.UTF8Encoding]::new($false)
        )
        if ($PSBoundParameters.ContainsKey('Token') -and
            -not [string]::IsNullOrEmpty($Token)) {
            [Environment]::SetEnvironmentVariable('GH_TOKEN', $Token, 'Process')
        }
        Invoke-Native -Command 'gh' -Arguments @(
            'pr', 'create', '--draft', '--base', $Base, '--head', $Head,
            '--title', $Title, '--body-file', $bodyPath
        )
    }
    finally {
        if ($PSBoundParameters.ContainsKey('Token') -and
            -not [string]::IsNullOrEmpty($Token)) {
            [Environment]::SetEnvironmentVariable('GH_TOKEN', $previousToken, 'Process')
        }
        if (Test-Path -LiteralPath $temporaryRoot) {
            Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
        }
    }
}

function Invoke-GhPagedJson {
    param(
        [string]$Endpoint,
        [AllowNull()][string]$Token = $null
    )

    if ($PSBoundParameters.ContainsKey('Token')) {
        Invoke-GhPagedReadJson -Endpoint $Endpoint -Token $Token
    }
    else {
        Invoke-GhPagedReadJson -Endpoint $Endpoint
    }
}

function Get-ImmutableProtocolReleaseEvidence {
    param(
        [string]$Repository,
        [string]$Tag,
        [string]$ProtocolToken
    )

    if ($Tag -cnotmatch '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') {
        throw "Selected protocol target '$Tag' is not a canonical release tag."
    }
    $release = Invoke-GhReadJson `
        -Endpoint "repos/$Repository/releases/tags/$Tag" `
        -Token $ProtocolToken
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

    $reference = Invoke-GhReadJson `
        -Endpoint "repos/$Repository/git/ref/tags/$Tag" `
        -Token $ProtocolToken
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
        $annotatedTag = Invoke-GhReadJson `
            -Endpoint "repos/$Repository/git/tags/$objectSha" `
            -Token $ProtocolToken
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
    $user = Invoke-GhReadJson -Endpoint 'user'
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

function Get-LocalGitBlobBytes {
    param(
        [Parameter(Mandatory)][string]$RepositoryPath,
        [Parameter(Mandatory)][string]$BlobSha
    )

    if ($BlobSha -cnotmatch '^[0-9a-f]{40}$') {
        throw "Local Git blob SHA '$BlobSha' is not canonical."
    }
    $fullRepositoryPath = [IO.Path]::GetFullPath($RepositoryPath)
    if (-not (Test-Path -LiteralPath $fullRepositoryPath -PathType Container)) {
        throw "Local Git repository path does not exist: $fullRepositoryPath"
    }
    $gitApplications = @(Get-Command git -CommandType Application `
        -ErrorAction Stop | Select-Object -First 1)
    if ($gitApplications.Count -ne 1 -or
        [string]::IsNullOrWhiteSpace([string]$gitApplications[0].Source)) {
        throw 'Git application could not be resolved for binary blob inspection.'
    }

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = [string]$gitApplications[0].Source
    $startInfo.Arguments = "cat-file blob $BlobSha"
    $startInfo.WorkingDirectory = $fullRepositoryPath
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) {
            throw "Git blob inspection did not start for '$BlobSha'."
        }
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $stream = [IO.MemoryStream]::new()
        try {
            $process.StandardOutput.BaseStream.CopyTo($stream)
            $process.WaitForExit()
            $stderr = $stderrTask.GetAwaiter().GetResult().Trim()
            if ($process.ExitCode -ne 0) {
                $detail = if ($stderr) { ": $stderr" } else { '' }
                throw "Git blob inspection failed for '$BlobSha'$detail"
            }
            return ,$stream.ToArray()
        }
        finally {
            $stream.Dispose()
        }
    }
    finally {
        $process.Dispose()
    }
}

function Assert-WorktreeBlobMatchesBase {
    param(
        [Parameter(Mandatory)][string]$RepositoryPath,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$ExpectedBlobSha,
        [Parameter(Mandatory)][string]$Label
    )

    if ($RelativePath -cnotmatch
            '^[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*$' -or
        $ExpectedBlobSha -cnotmatch '^[0-9a-f]{40}$') {
        throw "$Label has a noncanonical path or base blob identity."
    }
    $filteredBlob = ((Invoke-Native -Command 'git' -Arguments @(
        '-C', $RepositoryPath, 'hash-object', "--path=$RelativePath",
        '--filters', '--', $RelativePath
    )) -join '').Trim()
    if ($filteredBlob -cnotmatch '^[0-9a-f]{40}$' -or
        $filteredBlob -cne $ExpectedBlobSha) {
        throw "$Label worktree content differs from the committed base after Git clean filters."
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

function Get-OrdinalUniquePaths {
    param([AllowEmptyCollection()][object[]]$Paths)

    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    $values = [System.Collections.Generic.List[string]]::new()
    foreach ($value in @($Paths)) {
        $path = [string]$value
        if ([string]::IsNullOrWhiteSpace($path) -or -not $seen.Add($path)) {
            throw "Migration path set contains an empty or duplicate path '$path'."
        }
        $values.Add($path)
    }
    $result = $values.ToArray()
    [Array]::Sort($result, [StringComparer]::Ordinal)
    return $result
}

function Get-Sha256Text {
    param([Parameter(Mandatory)][string]$Text)

    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Text)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $algorithm.Dispose()
    }
}

function Get-MigrationPathSetSha256 {
    param([AllowEmptyCollection()][object[]]$Paths)

    $ordered = @(Get-OrdinalUniquePaths -Paths $Paths)
    return Get-Sha256Text -Text (($ordered -join "`n") + "`n")
}

function Test-ExactOrdinalPathSet {
    param(
        [AllowEmptyCollection()][object[]]$Actual,
        [AllowEmptyCollection()][object[]]$Expected
    )

    try {
        $actualPaths = @(Get-OrdinalUniquePaths -Paths $Actual)
        $expectedPaths = @(Get-OrdinalUniquePaths -Paths $Expected)
    }
    catch {
        return $false
    }
    if ($actualPaths.Count -ne $expectedPaths.Count) {
        return $false
    }
    for ($index = 0; $index -lt $actualPaths.Count; $index++) {
        if ([string]$actualPaths[$index] -cne [string]$expectedPaths[$index]) {
            return $false
        }
    }
    return $true
}

function Assert-ContainedMigrationDestination {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$RelativePath
    )

    if ([IO.Path]::IsPathRooted($RelativePath) -or
        $RelativePath -match '(^|/|\\)\.\.($|/|\\)' -or
        $RelativePath.Contains('\') -or $RelativePath.StartsWith('./')) {
        throw "Consumer migration path '$RelativePath' is not canonical."
    }
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd(
        [IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar
    )
    $full = [IO.Path]::GetFullPath((Join-Path $rootFull `
        ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)))
    $prefix = $rootFull + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Consumer migration path '$RelativePath' escapes the repository root."
    }
    $relativeParts = $RelativePath.Split('/')
    $cursor = $rootFull
    for ($index = 0; $index -lt $relativeParts.Count - 1; $index++) {
        $cursor = Join-Path $cursor $relativeParts[$index]
        if (-not (Test-Path -LiteralPath $cursor)) { continue }
        $item = Get-Item -LiteralPath $cursor -Force
        if (-not $item.PSIsContainer -or
            ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Consumer migration path '$RelativePath' traverses a linked or non-directory component."
        }
    }
    if (Test-Path -LiteralPath $full) {
        $leaf = Get-Item -LiteralPath $full -Force
        if ($leaf.PSIsContainer -or
            ($leaf.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Consumer migration path '$RelativePath' resolves to a linked or non-file destination."
        }
    }
    return $full
}

function Import-ConsumerMigrationCatalogAtCommit {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$Commit
    )

    $indexEntry = Get-LocalTreeEntry -RepositoryPath $SourcePath `
        -Commit $Commit -Path $ConsumerMigrationIndexPath
    if (-not $indexEntry.Path) {
        return $null
    }
    $moduleEntry = Get-LocalTreeEntry -RepositoryPath $SourcePath `
        -Commit $Commit -Path $ConsumerMigrationModulePath
    if ($indexEntry.Mode -cne '100644' -or $indexEntry.Type -cne 'blob' -or
        $moduleEntry.Mode -cne '100644' -or $moduleEntry.Type -cne 'blob') {
        throw 'Consumer migration capability is partial or not stored as regular immutable blobs.'
    }
    Invoke-Native -Command 'git' -Arguments @(
        '-C', $SourcePath, 'checkout', '--quiet', '--detach', $Commit
    ) | Out-Null
    $indexFile = Join-Path $SourcePath `
        ($ConsumerMigrationIndexPath -replace '/', [IO.Path]::DirectorySeparatorChar)
    $catalog = Import-MeAndAIConsumerMigrationCatalog -IndexPath $indexFile
    if ([string]$catalog.IndexBlob -cne [string]$indexEntry.Sha) {
        throw 'Consumer migration index bytes do not match the immutable target tree.'
    }
    foreach ($migration in @($catalog.Migrations)) {
        $definitionPath = "migrations/$([string]$migration.Definition)"
        $entry = Get-LocalTreeEntry -RepositoryPath $SourcePath `
            -Commit $Commit -Path $definitionPath
        if ($entry.Mode -cne '100644' -or $entry.Type -cne 'blob' -or
            [string]$entry.Sha -cne [string]$migration.DefinitionBlob) {
            throw "Consumer migration '$([string]$migration.Id)' does not match its immutable definition blob."
        }
    }
    return $catalog
}

function New-EmptyConsumerMigrationPlan {
    return [pscustomobject]@{
        Schema = 1
        State = 'Satisfied'
        LedgerWasMissing = $true
        Migrations = @()
        Paths = @()
        Ledger = [pscustomobject]@{
            Path = $ConsumerMigrationLedgerPath
            OriginalBlob = ''
            ResultBlob = ''
            Changed = $false
            ResultBytes = [byte[]]::new(0)
        }
        ExpectedChangedPaths = @()
        PlanSha256 = Get-Sha256Text -Text "schema=1`nno-catalog=1`n"
    }
}

function Get-ConsumerMigrationPlanForBase {
    param(
        [AllowNull()]$Catalog,
        [Parameter(Mandatory)][string]$BaseCommit,
        [Parameter(Mandatory)][string]$Workspace
    )

    $ledgerEntry = Get-LocalTreeEntry -Commit $BaseCommit `
        -Path $ConsumerMigrationLedgerPath
    $ledgerPath = Assert-ContainedMigrationDestination -Root $Workspace `
        -RelativePath $ConsumerMigrationLedgerPath
    $ledgerBytes = $null
    if ($ledgerEntry.Path) {
        if ($ledgerEntry.Mode -cne '100644' -or $ledgerEntry.Type -cne 'blob' -or
            -not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)) {
            throw 'Consumer migration ledger is not one regular tracked file.'
        }
        Assert-WorktreeBlobMatchesBase -RepositoryPath $Workspace `
            -RelativePath $ConsumerMigrationLedgerPath `
            -ExpectedBlobSha ([string]$ledgerEntry.Sha) `
            -Label 'Consumer migration ledger'
        $ledgerBytes = Get-LocalGitBlobBytes -RepositoryPath $Workspace `
            -BlobSha ([string]$ledgerEntry.Sha)
    }
    elseif (Test-Path -LiteralPath $ledgerPath) {
        throw 'Consumer migration ledger exists outside the committed base tree.'
    }
    if ($null -eq $Catalog) {
        if ($null -ne $ledgerBytes) {
            throw 'Consumer migration ledger exists but the installed protocol has no migration catalog.'
        }
        return New-EmptyConsumerMigrationPlan
    }

    $requiredPaths = @(Get-MeAndAIConsumerMigrationRequiredPaths `
        -Catalog $Catalog -LedgerBytes $ledgerBytes)
    $files = [System.Collections.Generic.List[object]]::new()
    foreach ($path in $requiredPaths) {
        $entry = Get-LocalTreeEntry -Commit $BaseCommit -Path $path
        $fullPath = Assert-ContainedMigrationDestination -Root $Workspace `
            -RelativePath $path
        if ($entry.Mode -cne '100644' -or $entry.Type -cne 'blob' -or
            -not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            throw "Consumer migration input '$path' is not one regular tracked file."
        }
        Assert-WorktreeBlobMatchesBase -RepositoryPath $Workspace `
            -RelativePath $path -ExpectedBlobSha ([string]$entry.Sha) `
            -Label "Consumer migration input '$path'"
        $files.Add([pscustomobject]@{
            Path = $path
            Bytes = Get-LocalGitBlobBytes -RepositoryPath $Workspace `
                -BlobSha ([string]$entry.Sha)
        })
    }
    $plan = Resolve-MeAndAIConsumerMigrationPlan -Catalog $Catalog `
        -Files @($files) -LedgerBytes $ledgerBytes
    foreach ($pathResult in @($plan.Paths)) {
        $entry = Get-LocalTreeEntry -Commit $BaseCommit `
            -Path ([string]$pathResult.Path)
        if ([string]$entry.Sha -cne [string]$pathResult.OriginalBlob) {
            throw "Consumer migration input '$([string]$pathResult.Path)' bytes differ from the committed base blob."
        }
    }
    if ($ledgerEntry.Path -and
        [string]$ledgerEntry.Sha -cne [string]$plan.Ledger.OriginalBlob) {
        throw 'Consumer migration ledger bytes differ from the committed base blob.'
    }
    return $plan
}

function Apply-ConsumerMigrationPlan {
    param(
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)][string]$Workspace
    )

    $writes = [System.Collections.Generic.List[object]]::new()
    foreach ($pathResult in @($Plan.Paths | Where-Object { [bool]$_.Changed })) {
        $fullPath = Assert-ContainedMigrationDestination -Root $Workspace `
            -RelativePath ([string]$pathResult.Path)
        $writes.Add([pscustomobject]@{
            Path = $fullPath
            Existed = $true
            OriginalBytes = [byte[]]$pathResult.OriginalBytes
            ResultBytes = [byte[]]$pathResult.ResultBytes
        })
    }
    if ([bool]$Plan.Ledger.Changed) {
        $ledgerPath = Assert-ContainedMigrationDestination -Root $Workspace `
            -RelativePath ([string]$Plan.Ledger.Path)
        $writes.Add([pscustomobject]@{
            Path = $ledgerPath
            Existed = -not [string]::IsNullOrEmpty([string]$Plan.Ledger.OriginalBlob)
            OriginalBytes = if ([string]::IsNullOrEmpty(
                [string]$Plan.Ledger.OriginalBlob
            )) { $null } else { [byte[]]$Plan.Ledger.OriginalBytes }
            ResultBytes = [byte[]]$Plan.Ledger.ResultBytes
        })
    }

    $completed = [System.Collections.Generic.List[object]]::new()
    try {
        foreach ($write in $writes) {
            $completed.Add($write)
            $parent = Split-Path -Parent ([string]$write.Path)
            if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }
            [IO.File]::WriteAllBytes(
                [string]$write.Path, [byte[]]$write.ResultBytes
            )
        }
    }
    catch {
        $writeError = $_.Exception
        $rollbackErrors = [System.Collections.Generic.List[string]]::new()
        for ($index = $completed.Count - 1; $index -ge 0; $index--) {
            $write = $completed[$index]
            try {
                if ([bool]$write.Existed) {
                    [IO.File]::WriteAllBytes(
                        [string]$write.Path, [byte[]]$write.OriginalBytes
                    )
                }
                elseif (Test-Path -LiteralPath ([string]$write.Path)) {
                    Remove-Item -LiteralPath ([string]$write.Path) -Force
                }
            }
            catch {
                $rollbackErrors.Add(
                    "$([string]$write.Path): $($_.Exception.Message)"
                )
            }
        }
        if ($rollbackErrors.Count -ne 0) {
            throw "Consumer migration write failed and rollback was incomplete: $($writeError.Message). Rollback: $($rollbackErrors -join '; ')"
        }
        throw $writeError
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
        [object[]]$Assets,
        [AllowNull()]$MigrationPlan = $null,
        [ValidateSet('Update', 'MigrationReconciliation')]
        [string]$ProposalKind = 'Update'
    )

    $paths = [System.Collections.Generic.List[string]]::new()
    if ($ProposalKind -ceq 'Update') {
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
    }
    if ($null -ne $MigrationPlan) {
        foreach ($path in @($MigrationPlan.ExpectedChangedPaths)) {
            $paths.Add([string]$path)
        }
    }
    return @(Get-OrdinalUniquePaths -Paths @($paths))
}

function Assert-StagedManagedUpdate {
    param(
        [string[]]$ExpectedPaths,
        [string]$TargetProtocolSha,
        [string]$SourcePath,
        [string]$ProtocolPath,
        [object[]]$Assets,
        [AllowNull()]$MigrationPlan = $null,
        [ValidateSet('Update', 'MigrationReconciliation')]
        [string]$ProposalKind = 'Update'
    )

    $stagedPaths = @(Invoke-Native -Command 'git' -Arguments @(
        'diff', '--cached', '--name-only'
    ))
    if (-not (Test-MeAndAIExactOrdinalPathSet `
        -Actual $stagedPaths -Expected $ExpectedPaths)) {
        throw "Upgrade staging does not match the expected managed paths: $($stagedPaths -join ', ')."
    }

    if ($ProposalKind -ceq 'Update') {
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
    if ($null -eq $MigrationPlan) { return }
    foreach ($pathResult in @($MigrationPlan.Paths | Where-Object { [bool]$_.Changed })) {
        $entry = Get-StagedTreeEntry -Path ([string]$pathResult.Path)
        if ($entry.Mode -cne '100644' -or
            [string]$entry.Sha -cne [string]$pathResult.ResultBlob) {
            throw "Staged migration result '$([string]$pathResult.Path)' does not match its deterministic plan."
        }
    }
    if ([bool]$MigrationPlan.Ledger.Changed) {
        $entry = Get-StagedTreeEntry -Path ([string]$MigrationPlan.Ledger.Path)
        if ($entry.Mode -cne '100644' -or
            [string]$entry.Sha -cne [string]$MigrationPlan.Ledger.ResultBlob) {
            throw 'Staged consumer migration ledger does not match its deterministic plan.'
        }
    }
}

function Assert-CommittedManagedUpdate {
    param(
        [Parameter(Mandatory)][string[]]$ExpectedPaths,
        [Parameter(Mandatory)][string]$BaseCommit,
        [Parameter(Mandatory)][string]$Commit,
        [Parameter(Mandatory)][string]$TargetProtocolSha,
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$ProtocolPath,
        [Parameter(Mandatory)][object[]]$Assets,
        [AllowNull()]$MigrationPlan = $null,
        [ValidateSet('Update', 'MigrationReconciliation')]
        [string]$ProposalKind = 'Update'
    )

    if ($BaseCommit -cnotmatch '^[0-9a-f]{40}$' -or
        $Commit -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Committed proposal validation requires canonical base and head commits.'
    }
    $parentLines = @(Invoke-Native -Command 'git' -Arguments @(
        'rev-list', '--parents', '-n', '1', $Commit
    ))
    $parentParts = if ($parentLines.Count -eq 1) {
        @([regex]::Split(([string]$parentLines[0]).Trim(), '\s+') |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }
    else { @() }
    if ($parentParts.Count -ne 2 -or
        [string]$parentParts[0] -cne $Commit -or
        [string]$parentParts[1] -cne $BaseCommit) {
        throw "Proposal commit '$Commit' is not based directly on the exact captured base '$BaseCommit'."
    }

    $committedPaths = @(Invoke-Native -Command 'git' -Arguments @(
        'diff', '--name-only', '--no-renames', $BaseCommit, $Commit, '--'
    ))
    if (-not (Test-MeAndAIExactOrdinalPathSet `
        -Actual $committedPaths -Expected $ExpectedPaths)) {
        throw "Committed proposal paths do not match the expected managed paths: $($committedPaths -join ', ')."
    }

    if ($ProposalKind -ceq 'Update') {
        $protocolEntry = Get-LocalTreeEntry -Commit $Commit -Path $ProtocolPath
        if ($protocolEntry.Mode -cne '160000' -or
            $protocolEntry.Type -cne 'commit' -or
            $protocolEntry.Sha -cne $TargetProtocolSha) {
            throw "Committed protocol gitlink does not match target commit '$TargetProtocolSha'."
        }
        foreach ($asset in $Assets) {
            if ([string]$asset.ConsumerPath -cnotin $ExpectedPaths) {
                continue
            }
            $targetEntry = Get-LocalTreeEntry -RepositoryPath $SourcePath `
                -Commit $TargetProtocolSha -Path ([string]$asset.TemplatePath)
            $committedEntry = Get-LocalTreeEntry -Commit $Commit `
                -Path ([string]$asset.ConsumerPath)
            if ($targetEntry.Mode -cne '100644' -or
                $targetEntry.Type -cne 'blob' -or
                $committedEntry.Mode -cne $targetEntry.Mode -or
                $committedEntry.Type -cne $targetEntry.Type -or
                $committedEntry.Sha -cne $targetEntry.Sha) {
                throw "Committed updater asset '$($asset.ConsumerPath)' does not match the target release blob."
            }
        }
    }
    if ($null -eq $MigrationPlan) { return }
    foreach ($pathResult in @($MigrationPlan.Paths | Where-Object { [bool]$_.Changed })) {
        $entry = Get-LocalTreeEntry -Commit $Commit `
            -Path ([string]$pathResult.Path)
        if ($entry.Mode -cne '100644' -or $entry.Type -cne 'blob' -or
            [string]$entry.Sha -cne [string]$pathResult.ResultBlob) {
            throw "Committed migration result '$([string]$pathResult.Path)' does not match its deterministic plan."
        }
    }
    if ([bool]$MigrationPlan.Ledger.Changed) {
        $entry = Get-LocalTreeEntry -Commit $Commit `
            -Path ([string]$MigrationPlan.Ledger.Path)
        if ($entry.Mode -cne '100644' -or $entry.Type -cne 'blob' -or
            [string]$entry.Sha -cne [string]$MigrationPlan.Ledger.ResultBlob) {
            throw 'Committed consumer migration ledger does not match its deterministic plan.'
        }
    }
}

function Stage-ManagedProposalTree {
    param(
        [Parameter(Mandatory)][string]$Workspace,
        [Parameter(Mandatory)][string]$BaseCommit,
        [Parameter(Mandatory)][string]$TargetProtocolSha,
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$ProtocolPath,
        [Parameter(Mandatory)][object[]]$Assets,
        [AllowNull()]$MigrationPlan = $null,
        [ValidateSet('Update', 'MigrationReconciliation')]
        [string]$ProposalKind = 'Update'
    )

    $expectedPaths = @(Get-ExpectedManagedPaths -BaseCommit $BaseCommit `
        -TargetProtocolSha $TargetProtocolSha -SourcePath $SourcePath `
        -ProtocolPath $ProtocolPath -Assets $Assets `
        -MigrationPlan $MigrationPlan -ProposalKind $ProposalKind)
    Push-Location -LiteralPath $Workspace
    try {
        if ($ProposalKind -ceq 'Update') {
            Invoke-Native -Command 'git' -Arguments @(
                '-C', $SourcePath, 'checkout', '--quiet', '--detach',
                $TargetProtocolSha
            ) | Out-Null
            Invoke-Native -Command 'git' -Arguments @(
                'update-index', '--add', '--cacheinfo',
                "160000,$TargetProtocolSha,$ProtocolPath"
            ) | Out-Null
            foreach ($asset in $Assets) {
                $templateRelative = [string]$asset.TemplatePath -replace '/', `
                    [IO.Path]::DirectorySeparatorChar
                $templatePath = Join-Path $SourcePath $templateRelative
                if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
                    throw "Target release checkout is missing updater template '$($asset.TemplatePath)'."
                }
                if ([string]$asset.ConsumerPath -cnotin $expectedPaths) {
                    continue
                }
                $consumerRelative = [string]$asset.ConsumerPath -replace '/', `
                    [IO.Path]::DirectorySeparatorChar
                $consumerPath = Join-Path $Workspace $consumerRelative
                $consumerParent = Split-Path -Parent $consumerPath
                if (-not (Test-Path -LiteralPath $consumerParent -PathType Container)) {
                    New-Item -ItemType Directory -Path $consumerParent -Force |
                        Out-Null
                }
                Copy-Item -LiteralPath $templatePath -Destination $consumerPath `
                    -Force
            }
        }
        if ($null -ne $MigrationPlan) {
            Apply-ConsumerMigrationPlan -Plan $MigrationPlan `
                -Workspace $Workspace
        }
        $addPaths = @($expectedPaths | Where-Object { $_ -cne $ProtocolPath })
        if ($addPaths.Count -ne 0) {
            Invoke-Native -Command 'git' -Arguments (@('add', '--') + $addPaths) |
                Out-Null
        }
        Assert-StagedManagedUpdate -ExpectedPaths $expectedPaths `
            -TargetProtocolSha $TargetProtocolSha -SourcePath $SourcePath `
            -ProtocolPath $ProtocolPath -Assets $Assets `
            -MigrationPlan $MigrationPlan -ProposalKind $ProposalKind
        return @($expectedPaths)
    }
    finally {
        Pop-Location
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
        Schema = 0; Kind = ''; Target = ''; ProtocolSha = ''
        MigrationPlanSha = ''; PathsSha = ''; Head = ''; Repository = ''
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
        if ($marker.schema -isnot [int] -and $marker.schema -isnot [long]) {
            return $empty
        }
        $schema = [long]$marker.schema
        $expectedNames = if ($schema -eq 1) {
            @('schema', 'target', 'protocolSha', 'head', 'repository')
        }
        elseif ($schema -eq 2) {
            @(
                'schema', 'kind', 'target', 'protocolSha',
                'migrationPlanSha', 'pathsSha', 'head', 'repository'
            )
        }
        else { return $empty }
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
        if ($marker.target -isnot [string] -or
            $marker.protocolSha -isnot [string] -or
            $marker.head -isnot [string] -or
            $marker.repository -isnot [string]) {
            return $empty
        }
        $kind = 'Update'
        $migrationPlanSha = ''
        $pathsSha = ''
        $canonical = if ($schema -eq 1) {
            [ordered]@{
                schema = 1
                target = [string]$marker.target
                protocolSha = [string]$marker.protocolSha
                head = [string]$marker.head
                repository = [string]$marker.repository
            }
        }
        else {
            if ($marker.kind -isnot [string] -or
                [string]$marker.kind -cnotin @('update', 'migration-reconciliation') -or
                $marker.migrationPlanSha -isnot [string] -or
                [string]$marker.migrationPlanSha -cnotmatch '^[0-9a-f]{64}$' -or
                $marker.pathsSha -isnot [string] -or
                [string]$marker.pathsSha -cnotmatch '^[0-9a-f]{64}$') {
                return $empty
            }
            $kind = if ([string]$marker.kind -ceq 'update') {
                'Update'
            } else { 'MigrationReconciliation' }
            $migrationPlanSha = [string]$marker.migrationPlanSha
            $pathsSha = [string]$marker.pathsSha
            [ordered]@{
                schema = 2
                kind = [string]$marker.kind
                target = [string]$marker.target
                protocolSha = [string]$marker.protocolSha
                migrationPlanSha = $migrationPlanSha
                pathsSha = $pathsSha
                head = [string]$marker.head
                repository = [string]$marker.repository
            }
        }
        $canonicalJson = $canonical | ConvertTo-Json -Compress
        if ($json -cne $canonicalJson) {
            return $empty
        }
        [pscustomobject]@{
            Schema = [int]$schema
            Kind = $kind
            Target = [string]$marker.target
            Head = [string]$marker.head
            ProtocolSha = [string]$marker.protocolSha
            MigrationPlanSha = $migrationPlanSha
            PathsSha = $pathsSha
            Repository = [string]$marker.repository
        }
    }
    catch {
        $empty
    }
}

function Get-ManagedUpdateIssueMarker {
    param([string]$Body)

    $empty = [pscustomobject]@{
        Schema = 0; Kind = ''; Target = ''; ProtocolSha = ''
        MigrationPlanSha = ''; Repository = ''; CanonicalLine = ''
    }
    if (-not $Body) { return $empty }
    $normalized = ([string]$Body).Replace("`r`n", "`n").Replace("`r", "`n")
    $prefix = '<!-- meandai-protocol-update-issue:'
    if (-not $normalized.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        return $empty
    }
    $signals = [regex]::Matches(
        $normalized, [regex]::Escape($prefix),
        [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if ($signals.Count -eq 0) { return $empty }
    $matches = [regex]::Matches(
        $normalized,
        '(?m)^<!-- meandai-protocol-update-issue:(?<json>\{[^\r\n]+\}) -->$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if ($signals.Count -ne 1 -or $matches.Count -ne 1 -or
        $matches[0].Index -ne 0) {
        throw 'A managed protocol-update issue contains a malformed ownership marker.'
    }
    try {
        $json = [string]$matches[0].Groups['json'].Value
        $marker = $json | ConvertFrom-Json
        if ($marker.schema -isnot [int] -and $marker.schema -isnot [long]) {
            throw 'schema'
        }
        $schema = [long]$marker.schema
        $properties = @($marker.PSObject.Properties)
        $expectedNames = if ($schema -eq 1) {
            @('schema', 'target', 'protocolSha', 'repository')
        }
        elseif ($schema -eq 2) {
            @(
                'schema', 'kind', 'target', 'protocolSha',
                'migrationPlanSha', 'repository'
            )
        }
        else { throw 'schema' }
        if ($properties.Count -ne $expectedNames.Count) { throw 'shape' }
        for ($index = 0; $index -lt $expectedNames.Count; $index++) {
            if ([string]$properties[$index].Name -cne $expectedNames[$index]) { throw 'shape' }
        }
        if ($marker.target -isnot [string] -or
            $marker.protocolSha -isnot [string] -or
            $marker.repository -isnot [string]) {
            throw 'type'
        }
        $kind = 'Update'
        $migrationPlanSha = ''
        $canonical = if ($schema -eq 1) {
            [ordered]@{
                schema = 1
                target = [string]$marker.target
                protocolSha = [string]$marker.protocolSha
                repository = [string]$marker.repository
            }
        }
        else {
            if ($marker.kind -isnot [string] -or
                [string]$marker.kind -cnotin @(
                    'update', 'migration-reconciliation'
                ) -or
                $marker.migrationPlanSha -isnot [string] -or
                [string]$marker.migrationPlanSha -cnotmatch '^[0-9a-f]{64}$') {
                throw 'type'
            }
            $kind = if ([string]$marker.kind -ceq 'update') {
                'Update'
            }
            else { 'MigrationReconciliation' }
            $migrationPlanSha = [string]$marker.migrationPlanSha
            [ordered]@{
                schema = 2
                kind = [string]$marker.kind
                target = [string]$marker.target
                protocolSha = [string]$marker.protocolSha
                migrationPlanSha = $migrationPlanSha
                repository = [string]$marker.repository
            }
        }
        $canonicalJson = $canonical | ConvertTo-Json -Compress
        if ($json -cne $canonicalJson) { throw 'canonical' }
        return [pscustomobject]@{
            Schema = [int]$schema
            Kind = $kind
            Target = [string]$marker.target
            ProtocolSha = [string]$marker.protocolSha
            MigrationPlanSha = $migrationPlanSha
            Repository = [string]$marker.repository
            CanonicalLine = "<!-- meandai-protocol-update-issue:$canonicalJson -->"
        }
    }
    catch {
        throw 'A managed protocol-update issue contains a malformed ownership marker.'
    }
}

function Get-ManagedUpdateIssueContract {
    param(
        [string]$Repository,
        [string]$TargetTag,
        [string]$ProtocolSha,
        [string]$Branch,
        [ValidateSet('Update', 'MigrationReconciliation')]
        [string]$ProposalKind = 'Update',
        [string]$MigrationPlanSha = ''
    )

    $useSchema2 = -not [string]::IsNullOrEmpty($MigrationPlanSha)
    if ($useSchema2 -and $MigrationPlanSha -cnotmatch '^[0-9a-f]{64}$') {
        throw 'A managed proposal requires one lowercase migration plan SHA-256.'
    }
    if (-not $useSchema2 -and $ProposalKind -cne 'Update') {
        throw 'Migration reconciliation requires a deterministic migration plan.'
    }
    $markerObject = if ($useSchema2) {
        [ordered]@{
            schema = 2
            kind = if ($ProposalKind -ceq 'Update') {
                'update'
            } else { 'migration-reconciliation' }
            target = $TargetTag
            protocolSha = $ProtocolSha
            migrationPlanSha = $MigrationPlanSha
            repository = $Repository
        }
    }
    else {
        [ordered]@{
            schema = 1; target = $TargetTag; protocolSha = $ProtocolSha
            repository = $Repository
        }
    }
    $markerJson = $markerObject | ConvertTo-Json -Compress
    $marker = "<!-- meandai-protocol-update-issue:$markerJson -->"
    $title = if ($ProposalKind -ceq 'Update') {
        "Track meAndAI protocol update to $TargetTag"
    }
    else { "Track meAndAI consumer reconciliation for $TargetTag" }
    $heading = if ($ProposalKind -ceq 'Update') {
        '## Managed protocol update tracking'
    }
    else { '## Managed consumer reconciliation tracking' }
    $bodyLines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in @(
        $marker,
        $heading, '',
        "- Target release: ``$TargetTag``",
        "- Protocol commit: ``$ProtocolSha``"
    )) {
        $bodyLines.Add([string]$line)
    }
    if ($useSchema2) {
        $bodyLines.Add("- Migration plan: ``$MigrationPlanSha``")
    }
    foreach ($line in @(
        "- Deterministic branch: ``$Branch``", '',
        'This issue is the canonical same-repository work record for the managed protocol proposal.',
        'The workflow creates or reuses it, the maintainer reviews and merges the draft, and post-merge finalization closes it only after exact branch convergence.'
    )) {
        $bodyLines.Add([string]$line)
    }
    $body = $bodyLines -join [Environment]::NewLine
    [pscustomobject]@{ Marker = $marker; Title = $title; Body = $body }
}

function Ensure-ManagedUpdateLabels {
    param([string]$Repository)

    $token = [string]$env:ISSUE_TOKEN
    if (-not $token -and -not $script:CurrentLauncher) {
        throw "Required workflow environment 'ISSUE_TOKEN' is missing."
    }
    $existing = @(Invoke-GhPagedJson -Endpoint "repos/$Repository/labels?per_page=100" -Token $token)
    $names = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($label in $existing) {
        if ($null -eq $label -or [string]::IsNullOrWhiteSpace([string]$label.name)) {
            throw 'Repository label inventory contains an invalid record.'
        }
        [void]$names.Add([string]$label.name)
    }
    foreach ($label in $ManagedUpdateLabels) {
        if ($names.Contains([string]$label.Name)) { continue }
        Invoke-GhJson -Token $token -Arguments @(
            'api', '--method', 'POST', "repos/$Repository/labels",
            '-f', "name=$($label.Name)", '-f', "color=$($label.Color)",
            '-f', "description=$($label.Description)"
        ) | Out-Null
        [void]$names.Add([string]$label.Name)
    }
}

function Get-ManagedUpdateIssueInventory {
    param([string]$Repository)

    $token = [string]$env:ISSUE_TOKEN
    if (-not $token -and -not $script:CurrentLauncher) {
        throw "Required workflow environment 'ISSUE_TOKEN' is missing."
    }
    @(Invoke-GhPagedJson -Endpoint "repos/$Repository/issues?state=all&per_page=100" -Token $token |
        Where-Object { $null -eq $_.PSObject.Properties['pull_request'] })
}

function Test-ExactLegacyQuoteStrippedProtocolUpdateIssue {
    param(
        $Issue,
        $Contract,
        [string]$Repository,
        [string]$TrustedActor
    )

    try {
        if ($null -eq $Issue -or $null -eq $Contract -or
            $Repository -cnotmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' -or
            [string]::IsNullOrWhiteSpace($TrustedActor) -or
            $null -ne $Issue.PSObject.Properties['pull_request'] -or
            [string]$Issue.number -cnotmatch '^[1-9][0-9]*$' -or
            [string]$Issue.state -cne 'open' -or
            $null -eq $Issue.PSObject.Properties['user'] -or
            [string]$Issue.user.login -cne $TrustedActor -or
            [string]$Issue.title -cne [string]$Contract.Title) {
            return [bool]$false
        }
        $contractMarker = Get-ManagedUpdateIssueMarker `
            -Body ([string]$Contract.Body)
        if ($contractMarker.CanonicalLine -cne [string]$Contract.Marker -or
            $contractMarker.Repository -cne $Repository) {
            return [bool]$false
        }
        $actual = ([string]$Issue.body).Replace("`r`n", "`n").Replace("`r", "`n")
        $expected = ([string]$Contract.Body).Replace('"', '').Replace(
            "`r`n", "`n"
        ).Replace("`r", "`n")
        return [bool]($actual -ceq $expected)
    }
    catch { return [bool]$false }
}

function Repair-LegacyQuoteStrippedProtocolUpdateIssue {
    param(
        [string]$Repository,
        [string]$TargetTag,
        [string]$ProtocolSha,
        [string]$Branch,
        [ValidateSet('Update', 'MigrationReconciliation')]
        [string]$ProposalKind = 'Update',
        [string]$MigrationPlanSha = '',
        [string]$TrustedActor
    )

    if ($Repository -cnotmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' -or
        $TargetTag -cnotmatch '^v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)$' -or
        $ProtocolSha -cnotmatch '^[0-9a-f]{40}$' -or
        [string]::IsNullOrWhiteSpace($Branch) -or
        [string]::IsNullOrWhiteSpace($TrustedActor)) {
        throw 'Legacy issue repair requires exact repository, target, branch, commit, and actor identities.'
    }
    $requestedContract = Get-ManagedUpdateIssueContract -Repository $Repository `
        -TargetTag $TargetTag -ProtocolSha $ProtocolSha -Branch $Branch `
        -ProposalKind $ProposalKind -MigrationPlanSha $MigrationPlanSha
    $targetIndex = $Branch.LastIndexOf($TargetTag, [StringComparison]::Ordinal)
    $branchTail = if ($targetIndex -ge 0) {
        $Branch.Substring($targetIndex + $TargetTag.Length)
    }
    else { '' }
    if ($targetIndex -lt 1 -or $branchTail -cnotin @('', '-recovery', '-migrations')) {
        throw 'Legacy issue repair could not derive the reserved branch namespace.'
    }
    $repairBranchPrefix = $Branch.Substring(0, $targetIndex)
    $token = [string]$env:ISSUE_TOKEN
    $repositoryRecord = Invoke-GhReadJson -Endpoint "repos/$Repository" `
        -Token $token
    if ([string]$repositoryRecord.full_name -cne $Repository) {
        throw 'Legacy issue repair repository identity did not resolve exactly.'
    }

    $issuesEndpoint = "repos/$Repository/issues?state=all&per_page=100"
    $inventory = @(Invoke-GhPagedReadJson -Endpoint $issuesEndpoint -Token $token)
    $poisoned = [System.Collections.Generic.List[object]]::new()
    $canonical = [System.Collections.Generic.List[object]]::new()
    $nearMatches = [System.Collections.Generic.List[object]]::new()
    foreach ($issue in $inventory) {
        if (Test-ExactLegacyQuoteStrippedProtocolUpdateIssue `
                -Issue $issue -Contract $requestedContract -Repository $Repository `
                -TrustedActor $TrustedActor) {
            $poisoned.Add([pscustomobject]@{
                Issue = $issue; Contract = $requestedContract; Branch = $Branch
            })
            continue
        }
        $body = [string]$issue.body
        $normalizedBody = $body.Replace("`r`n", "`n").Replace("`r", "`n")
        $hasManagedSignal = $normalizedBody.StartsWith(
            '<!-- meandai-protocol-update-issue:',
            [StringComparison]::OrdinalIgnoreCase
        )
        if ($hasManagedSignal) {
            $lines = @($normalizedBody.Split([char]"`n"))
            $legacyMatch = if ($lines.Count -gt 0) {
                [regex]::Match(
                    $lines[0],
                    '^<!-- meandai-protocol-update-issue:\{schema:2,kind:(?<kind>update|migration-reconciliation),target:(?<target>v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)),protocolSha:(?<sha>[0-9a-f]{40}),migrationPlanSha:(?<plan>[0-9a-f]{64}),repository:(?<repository>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)\} -->$',
                    [Text.RegularExpressions.RegexOptions]::CultureInvariant
                )
            }
            else { $null }
            $legacySchema = 2
            if ($null -eq $legacyMatch -or -not $legacyMatch.Success) {
                $legacyMatch = if ($lines.Count -gt 0) {
                    [regex]::Match(
                        $lines[0],
                        '^<!-- meandai-protocol-update-issue:\{schema:1,target:(?<target>v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)),protocolSha:(?<sha>[0-9a-f]{40}),repository:(?<repository>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)\} -->$',
                        [Text.RegularExpressions.RegexOptions]::CultureInvariant
                    )
                }
                else { $null }
                $legacySchema = 1
            }
            if ($null -ne $legacyMatch -and $legacyMatch.Success -and
                $legacyMatch.Groups['repository'].Value -ceq $Repository) {
                $derivedKind = if ($legacySchema -eq 2 -and
                    $legacyMatch.Groups['kind'].Value -ceq
                        'migration-reconciliation') {
                    'MigrationReconciliation'
                }
                else { 'Update' }
                $branchIndex = if ($legacySchema -eq 2) { 6 } else { 5 }
                $branchMatch = if ($lines.Count -gt $branchIndex) {
                    [regex]::Match(
                        $lines[$branchIndex],
                        '^- Deterministic branch: `(?<branch>[^`\r\n]+)`$',
                        [Text.RegularExpressions.RegexOptions]::CultureInvariant
                    )
                }
                else { $null }
                if ($null -ne $branchMatch -and $branchMatch.Success) {
                    $derivedTarget = $legacyMatch.Groups['target'].Value
                    $derivedBranch = $branchMatch.Groups['branch'].Value
                    $baseBranch = "$repairBranchPrefix$derivedTarget"
                    $allowedBranches = if ($derivedKind -ceq 'Update') {
                        @($baseBranch, "$baseBranch-recovery")
                    }
                    else { @("$baseBranch-migrations") }
                    if ($allowedBranches -ccontains $derivedBranch) {
                        $derivedContract = Get-ManagedUpdateIssueContract `
                            -Repository $Repository -TargetTag $derivedTarget `
                            -ProtocolSha $legacyMatch.Groups['sha'].Value `
                            -Branch $derivedBranch -ProposalKind $derivedKind `
                            -MigrationPlanSha $(if ($legacySchema -eq 2) {
                                $legacyMatch.Groups['plan'].Value
                            } else { '' })
                        if (Test-ExactLegacyQuoteStrippedProtocolUpdateIssue `
                                -Issue $issue -Contract $derivedContract `
                                -Repository $Repository `
                                -TrustedActor $TrustedActor) {
                            $poisoned.Add([pscustomobject]@{
                                Issue = $issue; Contract = $derivedContract
                                Branch = $derivedBranch
                            })
                            continue
                        }
                    }
                }
            }
        }
        $marker = $null
        try { $marker = Get-ManagedUpdateIssueMarker -Body $body }
        catch {
            if ($hasManagedSignal) { $nearMatches.Add($issue) }
            continue
        }
        if ($marker.Schema -gt 0) {
            $canonical.Add([pscustomobject]@{
                Issue = $issue; Marker = [string]$marker.CanonicalLine
            })
        }
        if ($marker.CanonicalLine -ceq [string]$requestedContract.Marker) {
            $expectedBody = ([string]$requestedContract.Body).Replace("`r`n", "`n").Replace(
                "`r", "`n"
            )
            if ([string]$issue.title -cne [string]$requestedContract.Title -or
                $normalizedBody -cne $expectedBody -or
                [string]$issue.state -cnotin @('open', 'closed') -or
                $null -ne $issue.PSObject.Properties['pull_request']) {
                $nearMatches.Add($issue)
            }
        }
    }
    if ($poisoned.Count -eq 0) {
        if ($nearMatches.Count -ne 0) {
            throw 'A managed protocol-update issue resembles the historical malformed record but is not exact.'
        }
        return [bool]$false
    }
    if ($poisoned.Count -ne 1 -or $nearMatches.Count -ne 0) {
        throw 'Legacy malformed protocol-update issue ownership is ambiguous.'
    }

    $candidate = $poisoned[0]
    $issue = $candidate.Issue
    $contract = $candidate.Contract
    $repairBranch = [string]$candidate.Branch
    if (@($canonical | Where-Object {
        [string]$_.Marker -ceq [string]$contract.Marker
    }).Count -ne 0) {
        throw 'Legacy malformed protocol-update issue has a canonical duplicate.'
    }
    if ($null -ne (Get-RemoteBranchHead -Branch $repairBranch)) {
        throw 'Legacy malformed protocol-update issue cannot be repaired while its reserved branch exists.'
    }
    $owner = $Repository.Split('/')[0]
    $pullsEndpoint = "repos/$Repository/pulls?state=all&head=$owner`:$repairBranch&per_page=100"
    if (@(Invoke-GhPagedReadJson -Endpoint $pullsEndpoint -Token $token).Count -ne 0) {
        throw 'Legacy malformed protocol-update issue cannot be repaired while a paired pull request exists.'
    }
    $commentsEndpoint = "repos/$Repository/issues/$([int]$issue.number)/comments?per_page=100"
    $comments = @(Invoke-GhPagedReadJson -Endpoint $commentsEndpoint -Token $token)
    if (@($comments | Where-Object {
        ([string]$_.body).StartsWith(
            '<!-- meandai-protocol-update-proposal:', [StringComparison]::Ordinal
        )
    }).Count -ne 0) {
        throw 'Legacy malformed protocol-update issue already has managed proposal evidence.'
    }

    $issueEndpoint = "repos/$Repository/issues/$([int]$issue.number)"
    $fresh = Invoke-GhReadJson -Endpoint $issueEndpoint -Token $token
    $freshRepository = Invoke-GhReadJson -Endpoint "repos/$Repository" -Token $token
    $freshPulls = @(Invoke-GhPagedReadJson -Endpoint $pullsEndpoint -Token $token)
    $freshComments = @(Invoke-GhPagedReadJson -Endpoint $commentsEndpoint -Token $token)
    if (-not (Test-ExactLegacyQuoteStrippedProtocolUpdateIssue `
            -Issue $fresh -Contract $contract -Repository $Repository `
            -TrustedActor $TrustedActor) -or
        [int]$fresh.number -ne [int]$issue.number -or
        [string]$freshRepository.full_name -cne $Repository -or
        $null -ne (Get-RemoteBranchHead -Branch $repairBranch) -or
        $freshPulls.Count -ne 0 -or
        @($freshComments | Where-Object {
            ([string]$_.body).StartsWith(
                '<!-- meandai-protocol-update-proposal:', [StringComparison]::Ordinal
            )
        }).Count -ne 0) {
        throw 'Legacy malformed protocol-update issue evidence changed before repair.'
    }

    [void](Invoke-GhMutationWithBodyFile -Method PATCH -Endpoint $issueEndpoint `
        -Body ([string]$contract.Body) -Token $token)
    $repaired = Invoke-GhReadJson -Endpoint $issueEndpoint -Token $token
    $repairedMarker = Get-ManagedUpdateIssueMarker -Body ([string]$repaired.body)
    $repairedBody = ([string]$repaired.body).Replace("`r`n", "`n").Replace(
        "`r", "`n"
    )
    $expectedBody = ([string]$contract.Body).Replace("`r`n", "`n").Replace(
        "`r", "`n"
    )
    if ($repairedMarker.CanonicalLine -cne [string]$contract.Marker -or
        [string]$repaired.title -cne [string]$contract.Title -or
        $repairedBody -cne $expectedBody -or
        [string]$repaired.state -cne 'open' -or
        [string]$repaired.user.login -cne $TrustedActor -or
        $null -ne $repaired.PSObject.Properties['pull_request']) {
        throw 'Legacy malformed protocol-update issue did not converge to the canonical contract.'
    }
    return [bool]$true
}

function Ensure-ProtocolUpdateIssue {
    param(
        [string]$Repository,
        [string]$TargetTag,
        [string]$ProtocolSha,
        [string]$Branch,
        [ValidateSet('Update', 'MigrationReconciliation')]
        [string]$ProposalKind = 'Update',
        [string]$MigrationPlanSha = '',
        [Parameter(Mandatory)][string]$TrustedActor
    )

    [void](Repair-LegacyQuoteStrippedProtocolUpdateIssue `
        -Repository $Repository -TargetTag $TargetTag `
        -ProtocolSha $ProtocolSha -Branch $Branch `
        -ProposalKind $ProposalKind -MigrationPlanSha $MigrationPlanSha `
        -TrustedActor $TrustedActor)
    Ensure-ManagedUpdateLabels -Repository $Repository
    $contract = Get-ManagedUpdateIssueContract -Repository $Repository `
        -TargetTag $TargetTag -ProtocolSha $ProtocolSha -Branch $Branch `
        -ProposalKind $ProposalKind -MigrationPlanSha $MigrationPlanSha
    $canonicalIssues = [System.Collections.Generic.List[object]]::new()
    foreach ($issue in @(Get-ManagedUpdateIssueInventory -Repository $Repository)) {
        $marker = Get-ManagedUpdateIssueMarker -Body ([string]$issue.body)
        if ($marker.Schema -eq 0) { continue }
        if ($marker.CanonicalLine -ceq $contract.Marker) {
            $normalizedBody = ([string]$issue.body).Replace("`r`n", "`n").TrimEnd([char[]]"`r`n")
            $normalizedExpected = $contract.Body.Replace("`r`n", "`n").TrimEnd([char[]]"`r`n")
            if ([string]$issue.title -cne $contract.Title -or
                $normalizedBody -cne $normalizedExpected -or
                [string]$issue.number -cnotmatch '^[1-9][0-9]*$' -or
                [string]$issue.state -cnotin @('open', 'closed')) {
                throw 'A canonically marked protocol-update issue has drifted from its exact owned record.'
            }
            $canonicalIssues.Add($issue)
        }
    }
    if ($canonicalIssues.Count -gt 1) {
        throw 'More than one canonical protocol-update issue exists for the same immutable target.'
    }
    if ($canonicalIssues.Count -eq 0) {
        $createdIssue = Invoke-GhMutationWithBodyFile -Method POST `
            -Endpoint "repos/$Repository/issues" -Body ([string]$contract.Body) `
            -Fields @(
                "title=$($contract.Title)", 'labels[]=type:task',
                'labels[]=priority:p1', 'labels[]=status:needs-review'
            ) -Token ([string]$env:ISSUE_TOKEN)
        $createdNumberText = if ($null -eq $createdIssue) { '' } else {
            [string]$createdIssue.number
        }
        if ($createdNumberText -cnotmatch '^[1-9][0-9]*$') {
            throw 'The created protocol-update issue response has no exact issue identity.'
        }
        $createdNumber = [int]$createdNumberText
        $createdIssue = Invoke-GhReadJson `
            -Endpoint "repos/$Repository/issues/$createdNumber" `
            -Token ([string]$env:ISSUE_TOKEN)
        $createdMarker = Get-ManagedUpdateIssueMarker `
            -Body ([string]$createdIssue.body)
        $createdBody = ([string]$createdIssue.body).Replace(
            "`r`n", "`n"
        ).TrimEnd([char[]]"`r`n")
        $expectedBody = ([string]$contract.Body).Replace(
            "`r`n", "`n"
        ).TrimEnd([char[]]"`r`n")
        $createdAuthor = ''
        $createdUserProperty = $createdIssue.PSObject.Properties['user']
        if ($null -ne $createdUserProperty -and
            $null -ne $createdUserProperty.Value) {
            $createdLoginProperty =
                $createdUserProperty.Value.PSObject.Properties['login']
            if ($null -ne $createdLoginProperty) {
                $createdAuthor = [string]$createdLoginProperty.Value
            }
        }
        if ([string]$createdIssue.number -cne $createdNumberText -or
            $createdMarker.CanonicalLine -cne [string]$contract.Marker -or
            [string]$createdIssue.title -cne [string]$contract.Title -or
            $createdBody -cne $expectedBody -or
            [string]$createdIssue.state -cne 'open' -or
            [string]::IsNullOrWhiteSpace($createdAuthor) -or
            $null -ne $createdIssue.PSObject.Properties['pull_request']) {
            throw 'The created protocol-update issue did not converge to its exact owned record.'
        }

        $visibleMatches = [System.Collections.Generic.List[object]]::new()
        foreach ($issue in @(Get-ManagedUpdateIssueInventory -Repository $Repository)) {
            $marker = Get-ManagedUpdateIssueMarker -Body ([string]$issue.body)
            if ($marker.CanonicalLine -ceq $contract.Marker) {
                $visibleMatches.Add($issue)
            }
        }
        if ($visibleMatches.Count -gt 1 -or
            ($visibleMatches.Count -eq 1 -and
                [string]$visibleMatches[0].number -cne $createdNumberText)) {
            throw 'The canonical protocol-update issue inventory raced after creation.'
        }
        $canonicalIssues.Add($createdIssue)
    }
    $canonical = $canonicalIssues[0]
    if ([string]$canonical.state -ceq 'closed') {
        Invoke-GhJson -Token ([string]$env:ISSUE_TOKEN) -Arguments @(
            'api', '--method', 'PATCH', "repos/$Repository/issues/$($canonical.number)",
            '-f', 'state=open'
        ) | Out-Null
    }
    Invoke-GhJson -Token ([string]$env:ISSUE_TOKEN) -Arguments @(
        'api', '--method', 'POST', "repos/$Repository/issues/$($canonical.number)/labels",
        '-f', 'labels[]=type:task', '-f', 'labels[]=priority:p1',
        '-f', 'labels[]=status:needs-review'
    ) | Out-Null
    Invoke-GhReadJson `
        -Endpoint "repos/$Repository/issues/$($canonical.number)" `
        -Token ([string]$env:ISSUE_TOKEN)
}

function Get-ManagedUpdateProposalEvidenceMarker {
    param([int]$PullRequestNumber, [string]$HeadSha)
    "<!-- meandai-protocol-update-proposal:pr-$PullRequestNumber`:head-$HeadSha -->"
}

function Set-ProtocolUpdateIssuePullRequestLink {
    param(
        [string]$Repository,
        [int]$IssueNumber,
        [int]$PullRequestNumber,
        [string]$HeadSha
    )

    $token = [string]$env:ISSUE_TOKEN
    $marker = Get-ManagedUpdateProposalEvidenceMarker `
        -PullRequestNumber $PullRequestNumber -HeadSha $HeadSha
    $comments = @(Invoke-GhPagedJson -Endpoint (
        "repos/$Repository/issues/$IssueNumber/comments?per_page=100"
    ) -Token $token)
    $managed = @($comments | Where-Object {
        ([string]$_.body).StartsWith(
            '<!-- meandai-protocol-update-proposal:', [StringComparison]::Ordinal
        )
    })
    $exact = @($managed | Where-Object {
        ([string]$_.body).Replace("`r`n", "`n").Split("`n")[0] -ceq $marker
    })
    $malformed = @($managed | Where-Object {
        ([string]$_.body).Replace("`r`n", "`n").Split("`n")[0] -cnotmatch
            '^<!-- meandai-protocol-update-proposal:pr-[1-9][0-9]*:head-[0-9a-f]{40} -->$'
    })
    if ($malformed.Count -ne 0 -or $exact.Count -gt 1) {
        throw 'The managed protocol-update issue has ambiguous proposal-link evidence.'
    }
    if ($exact.Count -eq 0) {
        $body = @(
            $marker,
            "Managed protocol proposal: #$PullRequestNumber",
            "Exact proposal head: ``$HeadSha``"
        ) -join [Environment]::NewLine
        Invoke-GhMutationWithBodyFile -Method POST `
            -Endpoint "repos/$Repository/issues/$IssueNumber/comments" `
            -Body $body -Token $token | Out-Null
    }
}

function Get-ValidatedManagedUpdateIssue {
    param(
        [string]$Repository,
        [int]$PullRequestNumber,
        [string]$TargetTag,
        [string]$ProtocolSha,
        [string]$HeadSha,
        [string]$Branch,
        [string]$PullRequestBody,
        [ValidateSet('Update', 'MigrationReconciliation')]
        [string]$ProposalKind = 'Update',
        [string]$MigrationPlanSha = '',
        [bool]$RequireOpen = $true
    )

    $issueNumber = Get-CanonicalTrackingIssueNumber -Body $PullRequestBody
    $issue = Invoke-GhReadJson -Endpoint "repos/$Repository/issues/$issueNumber" `
        -Token ([string]$env:ISSUE_TOKEN)
    if ($null -eq $issue -or [int]$issue.number -ne $issueNumber -or
        $null -ne $issue.PSObject.Properties['pull_request']) {
        throw "Managed update pull request #$PullRequestNumber tracking reference is not one same-repository issue."
    }
    $contract = Get-ManagedUpdateIssueContract -Repository $Repository `
        -TargetTag $TargetTag -ProtocolSha $ProtocolSha -Branch $Branch `
        -ProposalKind $ProposalKind -MigrationPlanSha $MigrationPlanSha
    $marker = Get-ManagedUpdateIssueMarker -Body ([string]$issue.body)
    $normalizedBody = ([string]$issue.body).Replace("`r`n", "`n").TrimEnd([char[]]"`r`n")
    $normalizedExpected = $contract.Body.Replace("`r`n", "`n").TrimEnd([char[]]"`r`n")
    if ($marker.CanonicalLine -cne $contract.Marker -or
        [string]$issue.title -cne $contract.Title -or
        $normalizedBody -cne $normalizedExpected -or
        [string]$issue.state -cnotin @('open', 'closed') -or
        ($RequireOpen -and [string]$issue.state -cne 'open')) {
        throw "Managed update pull request #$PullRequestNumber has no exact canonical tracking issue."
    }
    $evidenceMarker = Get-ManagedUpdateProposalEvidenceMarker `
        -PullRequestNumber $PullRequestNumber -HeadSha $HeadSha
    $comments = @(Invoke-GhPagedJson -Endpoint (
        "repos/$Repository/issues/$issueNumber/comments?per_page=100"
    ) -Token ([string]$env:ISSUE_TOKEN))
    $managedEvidence = @($comments | Where-Object {
        ([string]$_.body).StartsWith(
            '<!-- meandai-protocol-update-proposal:', [StringComparison]::Ordinal
        )
    })
    $exactEvidence = @($managedEvidence | Where-Object {
        ([string]$_.body).Replace("`r`n", "`n").Split("`n")[0] -ceq $evidenceMarker
    })
    $malformedEvidence = @($managedEvidence | Where-Object {
        ([string]$_.body).Replace("`r`n", "`n").Split("`n")[0] -cnotmatch
            '^<!-- meandai-protocol-update-proposal:pr-[1-9][0-9]*:head-[0-9a-f]{40} -->$'
    })
    if ($malformedEvidence.Count -ne 0 -or $exactEvidence.Count -ne 1) {
        throw "Managed update pull request #$PullRequestNumber has no exact issue-to-proposal backlink."
    }
    $issue
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

    $result = Invoke-Native -Command 'git' -Arguments @(
        'ls-remote', '--exit-code', '--heads', 'origin', "refs/heads/$Branch"
    ) -AcceptedExitCodes @(0, 2) -PassThruResult
    $output = @($result.Output)
    $exitCode = [int]$result.ExitCode
    if ($exitCode -eq 2) {
        return $null
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

function Assert-RemoteDefaultBranchUnchanged {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$DefaultBranch,
        [Parameter(Mandatory)][string]$ExpectedHeadSha
    )

    if ($ExpectedHeadSha -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Remote default-branch binding lacks one exact expected SHA.'
    }
    $metadata = Invoke-GhReadJson -Endpoint "repos/$Repository"
    $fullNameProperty = if ($null -ne $metadata) {
        $metadata.PSObject.Properties['full_name']
    }
    else { $null }
    $liveRepository = if ($null -ne $fullNameProperty) {
        [string]$fullNameProperty.Value
    }
    else { '' }
    if ($liveRepository -cne $Repository) {
        throw "Current-launcher live repository identity '$liveRepository' does not match '$Repository'; no GitHub mutation is permitted."
    }
    $defaultBranchProperty = $metadata.PSObject.Properties['default_branch']
    $liveDefaultBranch = if ($null -ne $defaultBranchProperty) {
        [string]$defaultBranchProperty.Value
    }
    else { '' }
    if ($liveDefaultBranch -cne $DefaultBranch) {
        throw "Consumer live default branch '$liveDefaultBranch' does not match captured '$DefaultBranch'; no GitHub mutation is permitted."
    }
    $observed = Get-RemoteBranchHead -Branch $DefaultBranch
    if ($null -eq $observed -or [string]$observed -cne $ExpectedHeadSha) {
        throw "Consumer default branch '$DefaultBranch' changed after recovery planning; no GitHub mutation is permitted."
    }
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
    param(
        [string]$Repository,
        [string]$HeadSha,
        [string]$Path,
        [AllowNull()][string]$Token = $null
    )

    $empty = [pscustomobject]@{ Mode = ''; Type = ''; Sha = '' }
    $segments = @($Path.Split('/', [StringSplitOptions]::RemoveEmptyEntries))
    if ($segments.Count -eq 0) {
        return $empty
    }

    $commit = if ($PSBoundParameters.ContainsKey('Token')) {
        Invoke-GhReadJson -Endpoint "repos/$Repository/git/commits/$HeadSha" `
            -Token $Token
    }
    else { Invoke-GhReadJson -Endpoint "repos/$Repository/git/commits/$HeadSha" }
    $treeSha = [string]$commit.tree.sha
    if ($treeSha -notmatch '^[0-9a-f]{40}$') {
        return $empty
    }

    for ($index = 0; $index -lt $segments.Count; $index++) {
        $tree = if ($PSBoundParameters.ContainsKey('Token')) {
            Invoke-GhReadJson -Endpoint "repos/$Repository/git/trees/$treeSha" `
                -Token $Token
        }
        else { Invoke-GhReadJson -Endpoint "repos/$Repository/git/trees/$treeSha" }
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

function Get-RepositoryBlobBytes {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$BlobSha,
        [AllowNull()][string]$Token = $null
    )

    if ($BlobSha -cnotmatch '^[0-9a-f]{40}$') {
        throw "Repository blob identity '$BlobSha' is not canonical."
    }
    $blob = if ($PSBoundParameters.ContainsKey('Token')) {
        Invoke-GhReadJson -Endpoint "repos/$Repository/git/blobs/$BlobSha" `
            -Token $Token
    }
    else { Invoke-GhReadJson -Endpoint "repos/$Repository/git/blobs/$BlobSha" }
    if ($null -eq $blob -or [string]$blob.sha -cne $BlobSha -or
        [string]$blob.encoding -cne 'base64' -or
        $null -eq $blob.PSObject.Properties['size'] -or
        [long]$blob.size -lt 0) {
        throw "Repository blob '$BlobSha' has invalid immutable metadata."
    }
    try {
        $encoded = ([string]$blob.content) -replace '[\r\n]', ''
        $bytes = [Convert]::FromBase64String($encoded)
    }
    catch {
        throw "Repository blob '$BlobSha' is not valid base64 content."
    }
    if ($bytes.LongLength -ne [long]$blob.size) {
        throw "Repository blob '$BlobSha' size does not match its immutable metadata."
    }
    return ,$bytes
}

function Get-RemoteConsumerMigrationPlan {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$BaseCommit,
        [Parameter(Mandatory)][string]$TargetProtocolSha,
        [Parameter(Mandatory)][string]$ProtocolToken
    )

    if ($BaseCommit -cnotmatch '^[0-9a-f]{40}$' -or
        $TargetProtocolSha -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Remote consumer migration planning requires canonical base and target commits.'
    }
    $moduleEntry = Get-RepositoryTreeEntry -Repository $ProtocolRepository `
        -HeadSha $TargetProtocolSha -Path $ConsumerMigrationModulePath `
        -Token $ProtocolToken
    $indexEntry = Get-RepositoryTreeEntry -Repository $ProtocolRepository `
        -HeadSha $TargetProtocolSha -Path $ConsumerMigrationIndexPath `
        -Token $ProtocolToken
    if ($moduleEntry.Mode -cne '100644' -or $moduleEntry.Type -cne 'blob' -or
        $indexEntry.Mode -cne '100644' -or $indexEntry.Type -cne 'blob') {
        throw 'Immutable target release lacks one regular migration engine and catalog index.'
    }

    $temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) (
        "meandai-finalizer-migrations-$([guid]::NewGuid().ToString('N'))"
    )
    $loadedModule = $null
    try {
        $scriptsRoot = Join-Path $temporaryRoot 'scripts'
        $catalogRoot = Join-Path $temporaryRoot 'migrations'
        New-Item -ItemType Directory -Path $scriptsRoot, $catalogRoot -Force | Out-Null
        $moduleBytes = Get-RepositoryBlobBytes -Repository $ProtocolRepository `
            -BlobSha ([string]$moduleEntry.Sha) -Token $ProtocolToken
        $indexBytes = Get-RepositoryBlobBytes -Repository $ProtocolRepository `
            -BlobSha ([string]$indexEntry.Sha) -Token $ProtocolToken
        $moduleFile = Join-Path $scriptsRoot 'MeAndAI.ConsumerMigrations.psm1'
        $indexFile = Join-Path $catalogRoot 'index.json'
        [IO.File]::WriteAllBytes($moduleFile, [byte[]]$moduleBytes)
        [IO.File]::WriteAllBytes($indexFile, [byte[]]$indexBytes)

        try {
            $indexText = [Text.UTF8Encoding]::new($false, $true).GetString(
                [byte[]]$indexBytes
            )
            $routingIndex = $indexText | ConvertFrom-Json
        }
        catch {
            throw 'Immutable target migration catalog index cannot be routed as strict UTF-8 JSON.'
        }
        if ($routingIndex.migrations -isnot [Array]) {
            throw 'Immutable target migration catalog index has no migration array.'
        }
        $definitionNames = [System.Collections.Generic.HashSet[string]]::new(
            [StringComparer]::Ordinal
        )
        foreach ($entry in @($routingIndex.migrations)) {
            $id = [string]$entry.id
            $definition = [string]$entry.definition
            if ($id -cnotmatch '^MIG-[0-9]{4}$' -or
                $definition -cne "$id.json" -or
                -not $definitionNames.Add($definition)) {
                throw 'Immutable target migration catalog index contains an unsafe definition route.'
            }
            $definitionPath = "migrations/$definition"
            $definitionEntry = Get-RepositoryTreeEntry `
                -Repository $ProtocolRepository -HeadSha $TargetProtocolSha `
                -Path $definitionPath -Token $ProtocolToken
            if ($definitionEntry.Mode -cne '100644' -or
                $definitionEntry.Type -cne 'blob') {
                throw "Immutable target migration definition '$definition' is not one regular blob."
            }
            $definitionBytes = Get-RepositoryBlobBytes `
                -Repository $ProtocolRepository -BlobSha ([string]$definitionEntry.Sha) `
                -Token $ProtocolToken
            [IO.File]::WriteAllBytes(
                (Join-Path $catalogRoot $definition), [byte[]]$definitionBytes
            )
        }

        $loadedModule = Import-Module $moduleFile -Force -PassThru
        $catalog = Import-MeAndAIConsumerMigrationCatalog -IndexPath $indexFile
        if ([string]$catalog.IndexBlob -cne [string]$indexEntry.Sha) {
            throw 'Imported target migration catalog differs from its immutable tree blob.'
        }
        foreach ($migration in @($catalog.Migrations)) {
            $definitionEntry = Get-RepositoryTreeEntry `
                -Repository $ProtocolRepository -HeadSha $TargetProtocolSha `
                -Path "migrations/$([string]$migration.Definition)" `
                -Token $ProtocolToken
            if ($definitionEntry.Mode -cne '100644' -or
                $definitionEntry.Type -cne 'blob' -or
                [string]$definitionEntry.Sha -cne [string]$migration.DefinitionBlob) {
                throw "Imported target migration '$([string]$migration.Id)' differs from its immutable tree blob."
            }
        }

        $ledgerEntry = Get-RepositoryTreeEntry -Repository $Repository `
            -HeadSha $BaseCommit -Path $ConsumerMigrationLedgerPath
        $ledgerBytes = $null
        if ($ledgerEntry.Mode -or $ledgerEntry.Type -or $ledgerEntry.Sha) {
            if ($ledgerEntry.Mode -cne '100644' -or $ledgerEntry.Type -cne 'blob') {
                throw 'Pull-request base migration ledger is not one regular blob.'
            }
            $ledgerBytes = Get-RepositoryBlobBytes -Repository $Repository `
                -BlobSha ([string]$ledgerEntry.Sha)
        }
        $requiredPaths = @(Get-MeAndAIConsumerMigrationRequiredPaths `
            -Catalog $catalog -LedgerBytes $ledgerBytes)
        $files = [System.Collections.Generic.List[object]]::new()
        $baseEntries = @{}
        foreach ($path in $requiredPaths) {
            $entry = Get-RepositoryTreeEntry -Repository $Repository `
                -HeadSha $BaseCommit -Path $path
            if ($entry.Mode -cne '100644' -or $entry.Type -cne 'blob') {
                throw "Pull-request base migration input '$path' is not one regular blob."
            }
            $bytes = Get-RepositoryBlobBytes -Repository $Repository `
                -BlobSha ([string]$entry.Sha)
            $files.Add([pscustomobject]@{ Path = $path; Bytes = [byte[]]$bytes })
            $baseEntries[$path] = $entry
        }
        $plan = Resolve-MeAndAIConsumerMigrationPlan -Catalog $catalog `
            -Files @($files) -LedgerBytes $ledgerBytes
        foreach ($pathResult in @($plan.Paths)) {
            if ([string]$baseEntries[[string]$pathResult.Path].Sha -cne
                [string]$pathResult.OriginalBlob) {
                throw "Remote migration input '$([string]$pathResult.Path)' differs from its base blob."
            }
        }
        if ($null -ne $ledgerBytes -and
            [string]$ledgerEntry.Sha -cne [string]$plan.Ledger.OriginalBlob) {
            throw 'Remote migration ledger differs from its base blob.'
        }
        return $plan
    }
    finally {
        if ($null -ne $loadedModule) {
            Remove-Module -ModuleInfo $loadedModule -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path -LiteralPath $temporaryRoot) {
            $resolvedTemporaryRoot = [IO.Path]::GetFullPath($temporaryRoot)
            $temporaryPrefix = [IO.Path]::GetFullPath(
                [IO.Path]::GetTempPath()
            ).TrimEnd([IO.Path]::DirectorySeparatorChar) +
                [IO.Path]::DirectorySeparatorChar
            if (-not $resolvedTemporaryRoot.StartsWith(
                $temporaryPrefix, [StringComparison]::OrdinalIgnoreCase
            )) {
                throw 'Remote migration temporary workspace escaped the system temporary directory.'
            }
            Remove-Item -LiteralPath $resolvedTemporaryRoot -Recurse -Force
        }
    }
}

function Assert-Schema2MergedProtocolEvidence {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)]$Marker,
        [Parameter(Mandatory)][ValidateSet('Update', 'MigrationReconciliation')]
        [string]$Kind,
        [Parameter(Mandatory)][string[]]$ChangedPaths
    )

    $release = Get-ImmutableProtocolReleaseEvidence `
        -Repository $ProtocolRepository -Tag ([string]$Marker.Target) `
        -ProtocolToken ([string]$env:PROTOCOL_TOKEN)
    if ([string]$release.CommitSha -cne [string]$Marker.ProtocolSha) {
        throw 'Schema-2 proposal marker does not match its immutable target release.'
    }
    $baseCommit = [string]$PullRequest.base.sha
    if ($baseCommit -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Schema-2 proposal has no canonical pull-request base commit.'
    }
    $targetSha = [string]$release.CommitSha
    $plan = Get-RemoteConsumerMigrationPlan -Repository $Repository `
        -BaseCommit $baseCommit -TargetProtocolSha $targetSha `
        -ProtocolToken ([string]$env:PROTOCOL_TOKEN)
    $baseProtocol = Get-RepositoryTreeEntry -Repository $Repository `
        -HeadSha $baseCommit -Path $ProtocolPath
    $headProtocol = Get-RepositoryTreeEntry -Repository $Repository `
        -HeadSha ([string]$Marker.Head) -Path $ProtocolPath
    if ($baseProtocol.Mode -cne '160000' -or $baseProtocol.Type -cne 'commit' -or
        $headProtocol.Mode -cne '160000' -or $headProtocol.Type -cne 'commit' -or
        [string]$headProtocol.Sha -cne $targetSha) {
        throw 'Schema-2 proposal protocol gitlink evidence is invalid.'
    }

    $expectedPaths = [System.Collections.Generic.List[string]]::new()
    foreach ($path in @($plan.ExpectedChangedPaths)) {
        $expectedPaths.Add([string]$path)
    }
    if ($Kind -ceq 'Update') {
        if ([string]$baseProtocol.Sha -ceq $targetSha) {
            throw 'Schema-2 update base already contains the target protocol.'
        }
        $lineage = Invoke-GhReadJson `
            -Endpoint "repos/$ProtocolRepository/compare/$([string]$baseProtocol.Sha)...$targetSha" `
            -Token ([string]$env:PROTOCOL_TOKEN)
        if ([string]$lineage.status -cne 'ahead') {
            throw 'Schema-2 update target is not a descendant of the base protocol commit.'
        }
        $expectedPaths.Add($ProtocolPath)
    }
    elseif ([string]$baseProtocol.Sha -cne $targetSha) {
        throw 'Schema-2 migration reconciliation base is not already pinned to its target protocol.'
    }

    foreach ($asset in $ManagedUpdaterAssets) {
        $targetEntry = Get-RepositoryTreeEntry -Repository $ProtocolRepository `
            -HeadSha $targetSha -Path ([string]$asset.TemplatePath) `
            -Token ([string]$env:PROTOCOL_TOKEN)
        $baseEntry = Get-RepositoryTreeEntry -Repository $Repository `
            -HeadSha $baseCommit -Path ([string]$asset.ConsumerPath)
        $headEntry = Get-RepositoryTreeEntry -Repository $Repository `
            -HeadSha ([string]$Marker.Head) -Path ([string]$asset.ConsumerPath)
        if ($targetEntry.Mode -cne '100644' -or $targetEntry.Type -cne 'blob' -or
            $baseEntry.Mode -cne '100644' -or $baseEntry.Type -cne 'blob' -or
            $headEntry.Mode -cne '100644' -or $headEntry.Type -cne 'blob' -or
            [string]$headEntry.Sha -cne [string]$targetEntry.Sha) {
            throw "Schema-2 proposal updater asset '$([string]$asset.ConsumerPath)' is not the immutable target blob."
        }
        if ([string]$baseEntry.Sha -cne [string]$targetEntry.Sha) {
            if ($Kind -cne 'Update') {
                throw "Schema-2 migration reconciliation has stale base updater asset '$([string]$asset.ConsumerPath)'."
            }
            $expectedPaths.Add([string]$asset.ConsumerPath)
        }
    }

    $expected = @(Get-OrdinalUniquePaths -Paths @($expectedPaths))
    if (-not (Test-ExactOrdinalPathSet `
        -Actual $ChangedPaths -Expected $expected)) {
        throw 'Schema-2 proposal changed paths differ from the independently computed plan.'
    }
    if ([string]$Marker.MigrationPlanSha -cne [string]$plan.PlanSha256 -or
        [string]$Marker.PathsSha -cne
            (Get-MigrationPathSetSha256 -Paths $expected)) {
        throw 'Schema-2 proposal marker differs from the independently computed plan.'
    }
    if (-not (Test-ConsumerMigrationEntriesMatchTarget `
        -Repository $Repository -HeadSha ([string]$Marker.Head) -Plan $plan)) {
        throw 'Schema-2 proposal migration output or ledger differs from the independently computed plan.'
    }
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

function Test-ConsumerMigrationEntriesMatchTarget {
    param(
        [string]$Repository,
        [string]$HeadSha,
        [Parameter(Mandatory)]$Plan
    )

    foreach ($pathResult in @($Plan.Paths | Where-Object { [bool]$_.Changed })) {
        $entry = Get-RepositoryTreeEntry -Repository $Repository `
            -HeadSha $HeadSha -Path ([string]$pathResult.Path)
        if ($entry.Mode -cne '100644' -or $entry.Type -cne 'blob' -or
            [string]$entry.Sha -cne [string]$pathResult.ResultBlob) {
            return $false
        }
    }
    if ([bool]$Plan.Ledger.Changed) {
        $entry = Get-RepositoryTreeEntry -Repository $Repository `
            -HeadSha $HeadSha -Path ([string]$Plan.Ledger.Path)
        if ($entry.Mode -cne '100644' -or $entry.Type -cne 'blob' -or
            [string]$entry.Sha -cne [string]$Plan.Ledger.ResultBlob) {
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
    $proposalKind = if ($null -ne $Operation.PSObject.Properties['ProposalKind']) {
        [string]$Operation.ProposalKind
    }
    else { 'Update' }
    $supersedeOnly = $null -ne $Operation.PSObject.Properties['SupersedeOnly'] -and
        $Operation.SupersedeOnly -is [bool] -and [bool]$Operation.SupersedeOnly
    $unboundIssue = $null -ne $Operation.PSObject.Properties['UnboundIssue'] -and
        $Operation.UnboundIssue -is [bool] -and [bool]$Operation.UnboundIssue
    $migrationPlan = if ($supersedeOnly) {
        New-EmptyConsumerMigrationPlan
    }
    else {
        $script:ConsumerMigrationPlansByTag[[string]$Operation.TargetTag]
    }
    if ($null -eq $migrationPlan) {
        throw "Managed PR #$number has no deterministic consumer migration plan."
    }
    $details = Invoke-GhReadJson -Endpoint "repos/$Repository/pulls/$number"
    $files = @(Invoke-GhPagedJson -Endpoint "repos/$Repository/pulls/$number/files?per_page=100")
    $marker = Get-ProtocolMarker ([string]$details.body)
    $protocolEntry = Get-RepositoryTreeEntry -Repository $Repository `
        -HeadSha ([string]$details.head.sha) -Path $ProtocolPath
    $remoteHead = Get-RemoteBranchHead -Branch ([string]$Operation.Branch)
    $changedPaths = @(Get-ValidatedPullRequestChangedPaths -Files $files)
    $expectedChangedPaths = @(Get-ExpectedManagedPaths -BaseCommit $BaseCommit `
        -TargetProtocolSha ([string]$Operation.ExpectedProtocolSha) `
        -SourcePath $SourcePath -ProtocolPath $ProtocolPath -Assets $ManagedAssets `
        -MigrationPlan $migrationPlan -ProposalKind $proposalKind)
    $managedAssetsMatch = if ($proposalKind -ceq 'Update') {
        Test-ManagedAssetEntriesMatchTarget `
            -Repository $Repository -HeadSha ([string]$details.head.sha) `
            -ExpectedPaths $expectedChangedPaths `
            -TargetProtocolSha ([string]$Operation.ExpectedProtocolSha) `
            -SourcePath $SourcePath -Assets $ManagedAssets
    }
    else { $true }
    $migrationEntriesMatch = Test-ConsumerMigrationEntriesMatchTarget `
        -Repository $Repository -HeadSha ([string]$details.head.sha) `
        -Plan $migrationPlan
    $expectedPathsSha = Get-MigrationPathSetSha256 -Paths $expectedChangedPaths
    $migrationMarkerValid = if ($marker.Schema -eq 2) {
        [string]$marker.Kind -ceq $proposalKind -and
        [string]$marker.MigrationPlanSha -ceq [string]$migrationPlan.PlanSha256 -and
        [string]$marker.PathsSha -ceq $expectedPathsSha
    }
    else { $marker.Schema -eq 1 -and $proposalKind -ceq 'Update' }
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
        Kind = $proposalKind
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
        AllowedExpectedPaths = @($ManagedPaths + @($migrationPlan.ExpectedChangedPaths) |
            Sort-Object -Unique)
        ManagedAssetEntriesMatchTarget = $managedAssetsMatch
        MigrationPlanSha = if ($marker.Schema -eq 2) {
            [string]$migrationPlan.PlanSha256
        } else { '' }
        MigrationPlanValid = $migrationMarkerValid -and $migrationEntriesMatch
        SupersedeOnly = $supersedeOnly
    }
    $context = [pscustomobject]@{
        Repository = $Repository; DefaultBranch = [string]$env:DEFAULT_BRANCH
        BranchPrefix = [string]$script:BranchPrefix
        ProtocolPath = $ProtocolPath; ManagedPaths = $ManagedPaths
        TrustedActor = $TrustedActor
        MigrationBranchSuffix = $MigrationBranchSuffix
        UpdateBranchSuffix = if ($script:CurrentLauncher) { '-recovery' } else { '' }
        ExpectedPullRequestState = $ExpectedPullRequestState
        ExpectedBranchExists = $ExpectedBranchExists
    }
    $problems = @(Get-MeAndAIProtocolCandidateProblems -Candidate $candidate -Context $context)

    if ($problems.Count -gt 0) {
        throw "Managed PR #$number changed after planning: $($problems -join '; ')."
    }
    if ($unboundIssue) {
        if (-not (Test-LegacyUnboundTrackingBody -Body ([string]$details.body))) {
            throw "Supersede-only PR #$number unexpectedly owns a canonical tracking issue."
        }
    }
    else {
        Get-ValidatedManagedUpdateIssue -Repository $Repository `
            -PullRequestNumber $number -TargetTag ([string]$Operation.TargetTag) `
            -ProtocolSha ([string]$Operation.ExpectedProtocolSha) `
            -HeadSha ([string]$Operation.ExpectedHeadSha) `
            -Branch ([string]$Operation.Branch) `
            -PullRequestBody ([string]$details.body) `
            -ProposalKind $proposalKind `
            -MigrationPlanSha $(if ($marker.Schema -eq 2) {
                [string]$migrationPlan.PlanSha256
            } else { '' }) `
            -RequireOpen $true | Out-Null
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

function Test-LegacyUnboundTrackingBody {
    param([string]$Body)

    $normalized = ([string]$Body).Replace("`r`n", "`n").Replace("`r", "`n")
    if ([regex]::IsMatch(
        $normalized,
        '(?im)(?:^|\s)(close[sd]?|fix(e[sd])?|resolve[sd]?)\s+(?:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)?#\d+\b',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )) {
        throw 'Legacy managed pull request uses an ambiguous native issue-closing keyword.'
    }
    $candidateLines = [regex]::Matches(
        $normalized,
        '(?im)^tracking[ \t]+issue[ \t]*:.*$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    $canonical = [regex]::Matches(
        $normalized,
        '(?m)^Tracking issue: #[1-9][0-9]*$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if ($canonical.Count -eq 1 -and $candidateLines.Count -eq 1 -and
        [string]$canonical[0].Value -ceq [string]$candidateLines[0].Value) {
        return $false
    }
    if ($candidateLines.Count -eq 0) {
        return $true
    }
    if ($candidateLines.Count -eq 1 -and
        [string]$candidateLines[0].Value -ceq 'Tracking issue: #REQUIRED') {
        return $true
    }
    throw 'Legacy managed pull request has ambiguous tracking-issue text.'
}

function Get-ExistingReplacementCandidates {
    param(
        [Parameter(Mandatory)][object[]]$Candidates,
        [Parameter(Mandatory)][string]$TargetTag,
        [ValidateSet('Update', 'MigrationReconciliation')]
        [string]$ProposalKind,
        [string]$MigrationPlanSha = '',
        [bool]$CurrentLauncherMode = $false,
        [string]$BranchPrefix = 'automation/meandai-protocol-',
        [string]$RecoveryBranchSuffix = '-recovery'
    )

    return @($Candidates | Where-Object {
        $supersedeOnly = $null -ne $_.PSObject.Properties['SupersedeOnly'] -and
            $_.SupersedeOnly -is [bool] -and [bool]$_.SupersedeOnly
        $baseMatch = -not $supersedeOnly -and
            [string]$_.TargetTag -ceq $TargetTag -and
            [string]$_.Kind -ceq $ProposalKind -and
            ($ProposalKind -ceq 'Update' -or
                [string]$_.MigrationPlanSha -ceq $MigrationPlanSha)
        if (-not $baseMatch) { return $false }
        if (-not $CurrentLauncherMode) { return $true }
        return [int]$_.MarkerSchema -eq 2 -and
            [string]$_.HeadRef -ceq
                "$BranchPrefix$TargetTag$RecoveryBranchSuffix"
    })
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

function Repair-LegacyInstallingUpdateTracking {
    param(
        [string]$Repository,
        [string]$DefaultBranch,
        [int]$Number
    )

    $pull = Invoke-GhReadJson -Endpoint "repos/$Repository/pulls/$Number"
    if ($null -eq $pull -or [int]$pull.number -ne $Number) {
        throw "Pull request #$Number could not be resolved exactly."
    }
    $body = [string]$pull.body
    $normalized = $body.Replace("`r`n", "`n").Replace("`r", "`n")
    $candidateLines = [regex]::Matches(
        $normalized, '(?im)^tracking[ \t]+issue[ \t]*:.*$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    $canonical = [regex]::Matches(
        $normalized, '(?m)^Tracking issue: #[1-9][0-9]*$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if ($candidateLines.Count -eq 1 -and $canonical.Count -eq 1 -and
        [string]$candidateLines[0].Value -ceq [string]$canonical[0].Value) {
        return
    }

    $headRef = [string]$pull.head.ref
    $hasUpdateSignal = $headRef.StartsWith($BranchPrefix, [StringComparison]::Ordinal) -or
        $body.IndexOf(
            '<!-- meandai-protocol-update:', [StringComparison]::OrdinalIgnoreCase
        ) -ge 0
    $hasAdoptionSignal = $headRef.StartsWith(
        'automation/meandai-capabilities-', [StringComparison]::Ordinal
    ) -or $body.IndexOf(
        '<!-- meandai-capabilities-adoption:', [StringComparison]::OrdinalIgnoreCase
    ) -ge 0
    if (-not $hasUpdateSignal -or $hasAdoptionSignal) { return }

    $legacyPlaceholder = $candidateLines.Count -eq 1 -and
        [string]$candidateLines[0].Value -ceq 'Tracking issue: #REQUIRED'
    if (($candidateLines.Count -ne 0 -and -not $legacyPlaceholder) -or
        [regex]::IsMatch(
            $normalized,
            '(?im)(?:^|\s)(close[sd]?|fix(e[sd])?|resolve[sd]?)\s+(?:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)?#\d+\b',
            [Text.RegularExpressions.RegexOptions]::CultureInvariant
        )) {
        throw "Managed installing update #$Number has an ambiguous tracking reference."
    }

    $marker = Get-ProtocolMarker -Body $body
    $firstLine = $normalized.Split("`n")[0]
    $markerJson = [ordered]@{
        schema = 1; target = [string]$marker.Target
        protocolSha = [string]$marker.ProtocolSha; head = [string]$marker.Head
        repository = [string]$marker.Repository
    } | ConvertTo-Json -Compress
    $canonicalLine = "<!-- meandai-protocol-update:$markerJson -->"
    $branch = [string]$pull.head.ref
    if ($marker.Schema -ne 1 -or $firstLine -cne $canonicalLine -or
        [string]$marker.Target -cnotmatch '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' -or
        $branch -cne "$BranchPrefix$([string]$marker.Target)" -or
        [string]$marker.Repository -cne $Repository -or
        [string]$pull.state -cne 'closed' -or
        $pull.merged -isnot [bool] -or -not [bool]$pull.merged -or
        [string]::IsNullOrWhiteSpace([string]$pull.merged_at) -or
        [string]$pull.base.ref -cne $DefaultBranch -or
        $null -eq $pull.head.repo -or
        [string]$pull.head.repo.full_name -cne $Repository -or
        [string]$pull.head.sha -cne [string]$marker.Head -or
        [string]$pull.merge_commit_sha -cnotmatch '^[0-9a-f]{40}$') {
        throw "Managed installing update #$Number does not satisfy the exact legacy-repair identity."
    }
    $files = @(Invoke-GhPagedJson -Endpoint "repos/$Repository/pulls/$Number/files?per_page=100")
    $changedPaths = @(Get-ValidatedPullRequestChangedPaths -Files $files)
    if ($changedPaths.Count -eq 0 -or $changedPaths -cnotcontains $ProtocolPath) {
        throw "Managed installing update #$Number has no protocol dependency change."
    }
    foreach ($path in $changedPaths) {
        if ($path -cnotin $ManagedPaths) {
            throw "Managed installing update #$Number changed unexpected path '$path'."
        }
    }
    $releaseEvidence = Get-ImmutableProtocolReleaseEvidence `
        -Repository $ProtocolRepository -Tag ([string]$marker.Target) `
        -ProtocolToken ([string]$env:PROTOCOL_TOKEN)
    if ([string]$releaseEvidence.CommitSha -cne [string]$marker.ProtocolSha) {
        throw "Managed installing update #$Number target marker does not match its immutable release commit."
    }
    foreach ($asset in $ManagedUpdaterAssets) {
        if ([string]$asset.ConsumerPath -cnotin $changedPaths) { continue }
        $expected = Get-RepositoryTreeEntry -Repository $ProtocolRepository `
            -HeadSha ([string]$releaseEvidence.CommitSha) `
            -Path ([string]$asset.TemplatePath) -Token ([string]$env:PROTOCOL_TOKEN)
        $observed = Get-RepositoryTreeEntry -Repository $Repository `
            -HeadSha ([string]$marker.Head) -Path ([string]$asset.ConsumerPath)
        if ($expected.Mode -cne '100644' -or $expected.Type -cne 'blob' -or
            $observed.Mode -cne $expected.Mode -or
            $observed.Type -cne $expected.Type -or
            $observed.Sha -cne $expected.Sha) {
            throw "Managed installing update #$Number updater asset '$($asset.ConsumerPath)' does not match the immutable target release template."
        }
    }
    $repositoryRecord = Invoke-GhReadJson -Endpoint "repos/$Repository"
    $defaultRef = Invoke-GhReadJson `
        -Endpoint "repos/$Repository/git/ref/heads/$DefaultBranch"
    $defaultHead = [string]$defaultRef.object.sha
    $protocolEntry = Get-RepositoryTreeEntry -Repository $Repository `
        -HeadSha $defaultHead -Path $ProtocolPath
    $comparison = Invoke-GhReadJson `
        -Endpoint "repos/$Repository/compare/$([string]$pull.merge_commit_sha)...$defaultHead"
    if ([string]$repositoryRecord.full_name -cne $Repository -or
        [string]$repositoryRecord.default_branch -cne $DefaultBranch -or
        [string]$defaultRef.ref -cne "refs/heads/$DefaultBranch" -or
        [string]$defaultRef.object.type -cne 'commit' -or
        $defaultHead -cnotmatch '^[0-9a-f]{40}$' -or
        $protocolEntry.Mode -cne '160000' -or
        $protocolEntry.Sha -cne [string]$marker.ProtocolSha -or
        [string]$comparison.status -cnotin @('identical', 'ahead')) {
        throw "Managed installing update #$Number is not the updater installed on the current default branch."
    }
    $branchHead = Get-RemoteBranchHead -Branch $branch
    if ($null -ne $branchHead -and [string]$branchHead -cne [string]$marker.Head) {
        throw "Managed installing update #$Number branch moved before tracking repair."
    }
    $owner = $Repository.Split('/')[0]
    $openReuse = @(Invoke-GhPagedJson -Endpoint (
        "repos/$Repository/pulls?state=open&head=$owner`:$branch&per_page=100"
    ))
    if ($openReuse.Count -ne 0) {
        throw "Managed installing update #$Number branch is reused by an open pull request."
    }

    $issue = Ensure-ProtocolUpdateIssue -Repository $Repository `
        -TargetTag ([string]$marker.Target) -ProtocolSha ([string]$marker.ProtocolSha) `
        -Branch $branch -TrustedActor (Get-AuthenticatedUpdaterActor)
    Set-ProtocolUpdateIssuePullRequestLink -Repository $Repository `
        -IssueNumber ([int]$issue.number) -PullRequestNumber $Number `
        -HeadSha ([string]$marker.Head)
    $trackingLine = "Tracking issue: #$([int]$issue.number)"
    $repairedBody = if ($legacyPlaceholder) {
        $normalized.Substring(0, $candidateLines[0].Index) + $trackingLine +
            $normalized.Substring($candidateLines[0].Index + $candidateLines[0].Length)
    }
    else {
        $normalized.TrimEnd([char[]]"`n") + [Environment]::NewLine +
            [Environment]::NewLine + $trackingLine
    }
    Invoke-GhMutationWithBodyFile -Method PATCH `
        -Endpoint "repos/$Repository/pulls/$Number" -Body $repairedBody `
        -Token ([string]$env:ISSUE_TOKEN) | Out-Null
    $repaired = Invoke-GhReadJson -Endpoint "repos/$Repository/pulls/$Number"
    if ((Get-CanonicalTrackingIssueNumber -Body ([string]$repaired.body)) -ne
        [int]$issue.number) {
        throw "Managed installing update #$Number tracking repair did not converge."
    }
}

function Get-ManagedMergedPullRequestState {
    param(
        [string]$Repository,
        [string]$DefaultBranch,
        [int]$Number
    )

    $pull = Invoke-GhReadJson -Endpoint "repos/$Repository/pulls/$Number"
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
    elseif ($updateMarker.Schema -in @(1, 2)) {
        $kind = [string]$updateMarker.Kind
        $marker = $updateMarker
        $canonicalObject = if ($updateMarker.Schema -eq 1) {
            [ordered]@{
                schema = 1
                target = [string]$updateMarker.Target
                protocolSha = [string]$updateMarker.ProtocolSha
                head = [string]$updateMarker.Head
                repository = [string]$updateMarker.Repository
            }
        }
        else {
            [ordered]@{
                schema = 2
                kind = if ([string]$updateMarker.Kind -ceq 'Update') {
                    'update'
                } else { 'migration-reconciliation' }
                target = [string]$updateMarker.Target
                protocolSha = [string]$updateMarker.ProtocolSha
                migrationPlanSha = [string]$updateMarker.MigrationPlanSha
                pathsSha = [string]$updateMarker.PathsSha
                head = [string]$updateMarker.Head
                repository = [string]$updateMarker.Repository
            }
        }
        $canonicalJson = $canonicalObject | ConvertTo-Json -Compress
        $canonicalLine = "<!-- meandai-protocol-update:$canonicalJson -->"
    }
    else {
        throw "Managed-looking pull request #$Number has no single canonical ownership marker."
    }
    if ($firstLine -cne $canonicalLine) {
        throw "Managed pull request #$Number ownership marker is not its exact first line."
    }

    $target = [string]$marker.Target
    $expectedBranches = if ($kind -ceq 'Adoption') {
        @("$adoptionPrefix$target")
    }
    elseif ($kind -ceq 'MigrationReconciliation') {
        @("$BranchPrefix$target$MigrationBranchSuffix")
    }
    elseif ($updateMarker.Schema -eq 2) {
        @("$BranchPrefix$target", "$BranchPrefix$target$RecoveryBranchSuffix")
    }
    else { @("$BranchPrefix$target") }
    if ($target -cnotmatch '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' -or
        $headRef -cnotin $expectedBranches -or
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
    if ($changedPaths.Count -eq 0) {
        throw "Managed pull request #$Number has no changed paths."
    }
    if ($kind -cin @('Adoption', 'Update') -and
        $changedPaths -cnotcontains $ProtocolPath) {
        throw "Managed $($kind.ToLowerInvariant()) pull request #$Number does not contain the protocol dependency path."
    }
    if ($kind -ceq 'MigrationReconciliation' -and
        ($changedPaths -ccontains $ProtocolPath -or
         $changedPaths -cnotcontains $ConsumerMigrationLedgerPath)) {
        throw "Managed migration pull request #$Number has an invalid protocol or ledger path contract."
    }
    if ($kind -ceq 'Update' -and $updateMarker.Schema -eq 1) {
        foreach ($path in $changedPaths) {
            if ($path -cnotin $ManagedPaths) {
                throw "Managed update pull request #$Number changed unexpected path '$path'."
            }
        }
    }
    elseif ($kind -ceq 'Adoption') {
        foreach ($forbiddenPath in @(
            '.ai/adoption/meandai-capabilities.json', 'FG_PAT.txt',
            'MEANDAI_RO_FG_PAT.txt'
        )) {
            if ($changedPaths -ccontains $forbiddenPath) {
                throw "Managed adoption pull request #$Number contains forbidden transient path '$forbiddenPath'."
            }
        }
    }
    else {
        foreach ($forbiddenPath in @(
            '.ai/adoption/meandai-capabilities.json', 'FG_PAT.txt',
            'MEANDAI_RO_FG_PAT.txt'
        )) {
            if ($changedPaths -ccontains $forbiddenPath) {
                throw "Managed protocol pull request #$Number contains forbidden path '$forbiddenPath'."
            }
        }
        if ([string]$updateMarker.PathsSha -cne
            (Get-MigrationPathSetSha256 -Paths $changedPaths)) {
            throw "Managed protocol pull request #$Number changed-path evidence is invalid."
        }
        Assert-Schema2MergedProtocolEvidence -Repository $Repository `
            -PullRequest $pull -Marker $updateMarker -Kind $kind `
            -ChangedPaths $changedPaths
    }

    $repositoryRecord = Invoke-GhReadJson -Endpoint "repos/$Repository"
    if ([string]$repositoryRecord.full_name -cne $Repository -or
        [string]$repositoryRecord.default_branch -cne $DefaultBranch) {
        throw 'Consumer default branch changed; explicit maintainer review is required.'
    }
    $defaultRef = Invoke-GhReadJson `
        -Endpoint "repos/$Repository/git/ref/heads/$DefaultBranch"
    $defaultHead = [string]$defaultRef.object.sha
    if ([string]$defaultRef.ref -cne "refs/heads/$DefaultBranch" -or
        [string]$defaultRef.object.type -cne 'commit' -or
        $defaultHead -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Consumer default branch head could not be resolved exactly.'
    }
    $comparison = Invoke-GhReadJson `
        -Endpoint "repos/$Repository/compare/$([string]$pull.merge_commit_sha)...$defaultHead"
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
        $issue = Get-ValidatedManagedUpdateIssue -Repository $Repository `
            -PullRequestNumber $Number -TargetTag $target `
            -ProtocolSha ([string]$marker.ProtocolSha) -HeadSha ([string]$marker.Head) `
            -Branch $headRef -PullRequestBody $body `
            -ProposalKind $kind `
            -MigrationPlanSha $(if ($updateMarker.Schema -eq 2) {
                [string]$updateMarker.MigrationPlanSha
            } else { '' }) `
            -RequireOpen $false
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
    foreach ($name in @(
        'GITHUB_REPOSITORY', 'DEFAULT_BRANCH', 'GH_TOKEN', 'ISSUE_TOKEN',
        'PROTOCOL_TOKEN'
    )) {
        if (-not [Environment]::GetEnvironmentVariable($name)) {
            throw "Required finalization environment '$name' is missing."
        }
    }
    $repository = [string]$env:GITHUB_REPOSITORY
    if ($repository -cnotmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        throw 'GITHUB_REPOSITORY is not a canonical owner/repository identity.'
    }
    $defaultBranch = [string]$env:DEFAULT_BRANCH
    Repair-LegacyInstallingUpdateTracking -Repository $repository `
        -DefaultBranch $defaultBranch -Number $Number
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
        Invoke-GhMutationWithBodyFile -Method POST `
            -Endpoint "repos/$repository/issues/$($afterBranch.IssueNumber)/comments" `
            -Body $comment | Out-Null
    }

    $liveIssue = Invoke-GhReadJson `
        -Endpoint "repos/$repository/issues/$($afterBranch.IssueNumber)"
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

function Invoke-LegacyInstallingUpdateRecovery {
    foreach ($name in @(
        'GITHUB_REPOSITORY', 'DEFAULT_BRANCH', 'GH_TOKEN', 'ISSUE_TOKEN',
        'PROTOCOL_TOKEN'
    )) {
        if (-not [Environment]::GetEnvironmentVariable($name)) {
            throw "Required finalization environment '$name' is missing."
        }
    }
    $repository = [string]$env:GITHUB_REPOSITORY
    if ($repository -cnotmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        throw 'GITHUB_REPOSITORY is not a canonical owner/repository identity.'
    }
    $owner = $repository.Split('/')[0]
    $branches = @(
        @(Get-RemoteBranchesByPrefix -Prefix $BranchPrefix) +
        @(Get-RemoteBranchesByPrefix -Prefix 'automation/meandai-capabilities-') |
            Sort-Object Name -Unique
    )
    $recovered = 0
    foreach ($branchRecord in $branches) {
        $branch = [string]$branchRecord.Name
        $closed = @(Invoke-GhPagedJson -Endpoint (
            "repos/$repository/pulls?state=closed&head=$owner`:$branch&per_page=100"
        ))
        if ($closed.Count -eq 0) { continue }
        if ($closed.Count -ne 1 -or [string]$closed[0].head.ref -cne $branch) {
            throw "Reserved managed branch '$branch' has ambiguous closed pull-request ownership."
        }
        Invoke-ManagedMergedPullRequestFinalization -Number ([int]$closed[0].number)
        $recovered++
    }
    Write-Host "Managed merge recovery completed; finalized $recovered exact retained branch(es)."
}

function Complete-SupersededProtocolUpdateIssue {
    param(
        [string]$Repository,
        $Operation,
        [int]$ReplacementPullRequestNumber = 0
    )

    if ($null -ne $Operation.PSObject.Properties['UnboundIssue'] -and
        $Operation.UnboundIssue -is [bool] -and [bool]$Operation.UnboundIssue) {
        return
    }
    $pullNumber = [int]$Operation.PullRequestNumber
    $pull = Invoke-GhReadJson -Endpoint "repos/$Repository/pulls/$pullNumber"
    $issue = Get-ValidatedManagedUpdateIssue -Repository $Repository `
        -PullRequestNumber $pullNumber -TargetTag ([string]$Operation.TargetTag) `
        -ProtocolSha ([string]$Operation.ExpectedProtocolSha) `
        -HeadSha ([string]$Operation.ExpectedHeadSha) -Branch ([string]$Operation.Branch) `
        -PullRequestBody ([string]$pull.body) `
        -ProposalKind $(if ($null -ne $Operation.PSObject.Properties['ProposalKind']) {
            [string]$Operation.ProposalKind
        } else { 'Update' }) `
        -MigrationPlanSha $(if ($null -ne $Operation.PSObject.Properties['MigrationPlanSha']) {
            [string]$Operation.MigrationPlanSha
        } else { '' }) `
        -RequireOpen $true
    $replacementIdentity = if ($ReplacementPullRequestNumber -gt 0) {
        "replacement-pr-$ReplacementPullRequestNumber"
    }
    else { 'default-branch-current' }
    $marker = "<!-- meandai-protocol-update-supersession:pr-$pullNumber`:head-$([string]$Operation.ExpectedHeadSha)`:$replacementIdentity -->"
    $comments = @(Invoke-GhPagedJson -Endpoint (
        "repos/$Repository/issues/$([int]$issue.number)/comments?per_page=100"
    ) -Token ([string]$env:ISSUE_TOKEN))
    $managed = @($comments | Where-Object {
        ([string]$_.body).StartsWith(
            '<!-- meandai-protocol-update-supersession:', [StringComparison]::Ordinal
        )
    })
    $exact = @($managed | Where-Object {
        ([string]$_.body).Replace("`r`n", "`n").Split("`n")[0] -ceq $marker
    })
    if ($managed.Count -ne $exact.Count -or $exact.Count -gt 1) {
        throw "Managed update issue #$([int]$issue.number) has ambiguous supersession evidence."
    }
    if ($exact.Count -eq 0) {
        $body = @(
            $marker,
            "Managed protocol proposal #$pullNumber was superseded after its exact branch was removed.",
            $(if ($ReplacementPullRequestNumber -gt 0) {
                "Verified replacement proposal: #$ReplacementPullRequestNumber"
            } else { 'The consumer default branch already contains the target protocol.' })
        ) -join [Environment]::NewLine
        Invoke-GhMutationWithBodyFile -Method POST `
            -Endpoint "repos/$Repository/issues/$([int]$issue.number)/comments" `
            -Body $body -Token ([string]$env:ISSUE_TOKEN) | Out-Null
    }
    $labels = @($issue.labels | ForEach-Object { [string]$_.name })
    foreach ($label in @('status:in-progress', 'status:needs-review', 'status:blocked')) {
        if ($labels -ccontains $label) {
            Invoke-GhJson -Token ([string]$env:ISSUE_TOKEN) -Arguments @(
                'api', '--method', 'DELETE',
                "repos/$Repository/issues/$([int]$issue.number)/labels/$([Uri]::EscapeDataString($label))"
            ) | Out-Null
        }
    }
    Invoke-GhJson -Token ([string]$env:ISSUE_TOKEN) -Arguments @(
        'api', '--method', 'PATCH', "repos/$Repository/issues/$([int]$issue.number)",
        '-f', 'state=closed', '-f', 'state_reason=not_planned'
    ) | Out-Null
    $closed = Invoke-GhReadJson `
        -Endpoint "repos/$Repository/issues/$([int]$issue.number)" `
        -Token ([string]$env:ISSUE_TOKEN)
    if ([string]$closed.state -cne 'closed') {
        throw "Superseded managed update issue #$([int]$issue.number) did not close."
    }
}

if (@(@(
    [bool]$FinalizeMergedPullRequest,
    [bool]$RecoverMergedPullRequests,
    [bool]$CurrentLauncher
    ) | Where-Object { $_ }).Count -gt 1) {
    throw 'Finalization, merged-branch recovery, and current-launcher modes are mutually exclusive.'
}
if ($CurrentLauncher) {
    if ($RequestedTargetTag -cnotmatch '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' -or
        $RequestedTargetCommit -cnotmatch '^[0-9a-f]{40}$' -or
        $RequestedBaseSha -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Current-launcher mode requires one canonical target tag, target commit, and consumer base SHA.'
    }
}
elseif ($RequestedTargetTag -or $RequestedTargetCommit -or $RequestedBaseSha) {
    throw 'Target-bound recovery inputs are valid only in current-launcher mode.'
}
if ($FinalizeMergedPullRequest) {
    Invoke-ManagedMergedPullRequestFinalization -Number $PullRequestNumber
    return
}
if ($RecoverMergedPullRequests) {
    Invoke-LegacyInstallingUpdateRecovery
    return
}

$requiredEnvironment = if ($CurrentLauncher) {
    @('GITHUB_REPOSITORY', 'GITHUB_WORKSPACE', 'DEFAULT_BRANCH')
}
else {
    @(
        'GITHUB_REPOSITORY', 'GITHUB_WORKSPACE', 'DEFAULT_BRANCH', 'GH_TOKEN',
        'PROTOCOL_TOKEN', 'ISSUE_TOKEN'
    )
}
foreach ($name in $requiredEnvironment) {
    if (-not [Environment]::GetEnvironmentVariable($name)) {
        throw "Required workflow environment '$name' is missing."
    }
}

$workspace = [IO.Path]::GetFullPath($env:GITHUB_WORKSPACE)
Set-Location -LiteralPath $workspace
$sourcePath = if ([IO.Path]::IsPathRooted($ProtocolSourcePath)) {
    [IO.Path]::GetFullPath($ProtocolSourcePath)
}
else {
    [IO.Path]::GetFullPath((Join-Path $workspace $ProtocolSourcePath))
}
$modulePath = if ($CurrentLauncher) {
    Join-Path $sourcePath `
        'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1'
}
else {
    Join-Path $workspace '.github/scripts/MeAndAI.ProtocolUpdate.psm1'
}
$consumerMigrationModule = Join-Path $sourcePath `
    ($ConsumerMigrationModulePath -replace '/', [IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    throw "Pure resolver is missing: $modulePath"
}
if (-not (Test-Path -LiteralPath (Join-Path $sourcePath '.git'))) {
    throw "Pinned protocol source checkout is missing: $sourcePath"
}
Import-Module $modulePath -Force
if (-not (Test-Path -LiteralPath $consumerMigrationModule -PathType Leaf)) {
    throw 'Installed updater declares consumer-migration capability but its pinned protocol source lacks the pure migration engine.'
}
Import-Module $consumerMigrationModule -Force
$TrustedActor = Get-AuthenticatedUpdaterActor

if ($CurrentLauncher) {
    $sourceHead = ((Invoke-Native -Command 'git' -Arguments @(
        '-C', $sourcePath, 'rev-parse', 'HEAD'
    )) -join '').Trim()
    $sourceTagHead = ((Invoke-Native -Command 'git' -Arguments @(
        '-C', $sourcePath, 'rev-list', '-n', '1', $RequestedTargetTag
    )) -join '').Trim()
    $sourceVersionPath = Join-Path $sourcePath 'VERSION'
    if ($sourceHead -cne $RequestedTargetCommit -or
        $sourceTagHead -cne $RequestedTargetCommit -or
        -not (Test-Path -LiteralPath $sourceVersionPath -PathType Leaf) -or
        [IO.File]::ReadAllText($sourceVersionPath).Trim() -cne
            $RequestedTargetTag.Substring(1)) {
        throw 'Current-launcher source does not match the exact requested immutable target.'
    }
}

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
if ($CurrentLauncher -and $baseHeadSha -cne $RequestedBaseSha) {
    throw 'Current-launcher consumer clone does not match the exact requested base SHA.'
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

$currentCatalog = Import-ConsumerMigrationCatalogAtCommit `
    -SourcePath $sourcePath -Commit $currentProtocolSha
if ($null -eq $currentCatalog -and -not $CurrentLauncher) {
    throw 'Installed updater declares consumer-migration capability but the current immutable protocol release has no catalog.'
}
$currentMigrationPlan = Get-ConsumerMigrationPlanForBase `
    -Catalog $currentCatalog -BaseCommit $baseHeadSha -Workspace $workspace
$script:ConsumerMigrationPlansByTag[$currentTag] = $currentMigrationPlan
$migrationManagedPaths = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::Ordinal
)
[void]$migrationManagedPaths.Add($ConsumerMigrationLedgerPath)
if ($null -ne $currentCatalog) {
    foreach ($migration in @($currentCatalog.Migrations)) {
        foreach ($operation in @($migration.Operations)) {
            [void]$migrationManagedPaths.Add([string]$operation.Path)
        }
    }
}

$orderedCompatibleTags = @(Get-MeAndAICompatibleProtocolTagsInOrder `
    -Tags $availableTags -CurrentTag $currentTag)
$previousCatalog = $currentCatalog
$catalogSeen = $null -ne $currentCatalog
$requestedTargetReached = $currentTag -ceq $RequestedTargetTag
foreach ($tag in $orderedCompatibleTags) {
    if ($tag -ceq $currentTag) {
        continue
    }
    $targetShaForCatalog = ((Invoke-Native -Command 'git' -Arguments @(
        '-C', $sourcePath, 'rev-list', '-n', '1', $tag
    )) -join '').Trim()
    if (-not (Test-GitAncestor -RepositoryPath $sourcePath `
            -Ancestor $currentProtocolSha -Descendant $targetShaForCatalog)) {
        continue
    }
    $targetCatalog = Import-ConsumerMigrationCatalogAtCommit `
        -SourcePath $sourcePath -Commit $targetShaForCatalog
    if ($null -eq $targetCatalog) {
        if (-not $CurrentLauncher -or $catalogSeen) {
            throw "Descendant protocol release '$tag' removed the consumer migration catalog."
        }
        $script:ConsumerMigrationPlansByTag[$tag] = New-EmptyConsumerMigrationPlan
        if ($CurrentLauncher -and $tag -ceq $RequestedTargetTag) {
            $requestedTargetReached = $true
            break
        }
        continue
    }
    if ($null -ne $previousCatalog) {
        Assert-MeAndAIConsumerMigrationCatalogChain `
            -Catalogs @($previousCatalog, $targetCatalog)
    }
    $targetPlan = Get-ConsumerMigrationPlanForBase `
        -Catalog $targetCatalog -BaseCommit $baseHeadSha -Workspace $workspace
    $script:ConsumerMigrationPlansByTag[$tag] = $targetPlan
    foreach ($migration in @($targetCatalog.Migrations)) {
        foreach ($operation in @($migration.Operations)) {
            [void]$migrationManagedPaths.Add([string]$operation.Path)
        }
    }
    $previousCatalog = $targetCatalog
    $catalogSeen = $true
    if ($CurrentLauncher -and $tag -ceq $RequestedTargetTag) {
        $requestedTargetReached = $true
        break
    }
}
if ($CurrentLauncher -and -not $requestedTargetReached) {
    throw "Requested target '$RequestedTargetTag' is absent from the compatible immutable release chain."
}
$ManagedPaths = @(Get-OrdinalUniquePaths -Paths @(
    @($ManagedPaths) + @($migrationManagedPaths)
))

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

    $details = Invoke-GhReadJson `
        -Endpoint "repos/$repository/pulls/$($pull.number)"
    $marker = Get-ProtocolMarker ([string]$details.body)
    $files = @(Invoke-GhPagedJson -Endpoint "repos/$repository/pulls/$($pull.number)/files?per_page=100")
    $headRef = [string]$details.head.ref
    $branchTail = if ($headRef.StartsWith($BranchPrefix, [StringComparison]::Ordinal)) {
        $headRef.Substring($BranchPrefix.Length)
    } else { '' }
    $proposalKind = if ($branchTail.EndsWith(
        $MigrationBranchSuffix, [StringComparison]::Ordinal
    )) {
        'MigrationReconciliation'
    } else { 'Update' }
    $target = if ($proposalKind -ceq 'MigrationReconciliation') {
        $branchTail.Substring(0, $branchTail.Length - $MigrationBranchSuffix.Length)
    }
    elseif ($CurrentLauncher -and $branchTail.EndsWith(
        $UpdateBranchSuffix, [StringComparison]::Ordinal
    )) {
        $branchTail.Substring(0, $branchTail.Length - $UpdateBranchSuffix.Length)
    }
    else { $branchTail }
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
    $schemaOneRecoveryCandidate = $CurrentLauncher -and
        $marker.Schema -eq 1 -and $proposalKind -ceq 'Update'
    $unboundLegacyIssue = $schemaOneRecoveryCandidate -and
        (Test-LegacyUnboundTrackingBody -Body ([string]$details.body))
    $migrationPlan = if ($schemaOneRecoveryCandidate) {
        New-EmptyConsumerMigrationPlan
    }
    elseif ($script:ConsumerMigrationPlansByTag.ContainsKey($target)) {
        $script:ConsumerMigrationPlansByTag[$target]
    } else { New-EmptyConsumerMigrationPlan }
    $migrationEntriesMatchTarget = $false
    if ($expectedProtocolSha -match '^[0-9a-f]{40}$') {
        $expectedChangedPaths = @(Get-ExpectedManagedPaths `
            -BaseCommit $baseHeadSha -TargetProtocolSha $expectedProtocolSha `
            -SourcePath $sourcePath -ProtocolPath $ProtocolPath `
            -Assets $ManagedUpdaterAssets -MigrationPlan $migrationPlan `
            -ProposalKind $proposalKind)
        $managedAssetsMatchTarget = if ($proposalKind -ceq 'Update') {
            Test-ManagedAssetEntriesMatchTarget `
                -Repository $repository -HeadSha ([string]$details.head.sha) `
                -ExpectedPaths $expectedChangedPaths `
                -TargetProtocolSha $expectedProtocolSha -SourcePath $sourcePath `
                -Assets $ManagedUpdaterAssets
        } else { $true }
        $migrationEntriesMatchTarget = Test-ConsumerMigrationEntriesMatchTarget `
            -Repository $repository -HeadSha ([string]$details.head.sha) `
            -Plan $migrationPlan
    }
    if (-not $unboundLegacyIssue -and $marker.Schema -in @(1, 2) -and
        $expectedProtocolSha -match '^[0-9a-f]{40}$') {
        Get-ValidatedManagedUpdateIssue -Repository $repository `
            -PullRequestNumber ([int]$details.number) -TargetTag $target `
            -ProtocolSha $expectedProtocolSha -HeadSha ([string]$details.head.sha) `
            -Branch $headRef -PullRequestBody ([string]$details.body) `
            -ProposalKind $proposalKind `
            -MigrationPlanSha $(if ($marker.Schema -eq 2) {
                [string]$migrationPlan.PlanSha256
            } else { '' }) `
            -RequireOpen $true | Out-Null
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
        Kind = $proposalKind
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
        AllowedExpectedPaths = @($ManagedPaths)
        ManagedAssetEntriesMatchTarget = $managedAssetsMatchTarget
        MigrationPlanSha = if ($marker.Schema -eq 2) {
            [string]$migrationPlan.PlanSha256
        } else { '' }
        MigrationPlanValid = $migrationEntriesMatchTarget -and
            (($marker.Schema -eq 1 -and $proposalKind -ceq 'Update') -or
             ($marker.Schema -eq 2 -and [string]$marker.Kind -ceq $proposalKind -and
              [string]$marker.MigrationPlanSha -ceq [string]$migrationPlan.PlanSha256 -and
               [string]$marker.PathsSha -ceq
                 (Get-MigrationPathSetSha256 -Paths $expectedChangedPaths)))
        SupersedeOnly = [bool]$schemaOneRecoveryCandidate
        UnboundIssue = [bool]$unboundLegacyIssue
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
    MigrationRequired = [string]$currentMigrationPlan.State -ceq 'ChangesRequired'
    CurrentMigrationPlanSha = [string]$currentMigrationPlan.PlanSha256
    MigrationBranchSuffix = $MigrationBranchSuffix
    UpdateBranchSuffix = $UpdateBranchSuffix
    Candidates = @($candidates)
}
if ($CurrentLauncher) {
    $snapshot | Add-Member -NotePropertyName RequestedTargetTag `
        -NotePropertyValue $RequestedTargetTag
}
$plan = Resolve-MeAndAIProtocolUpdatePlan -Snapshot $snapshot
Add-RunSummary "## meAndAI protocol update`n`n- Current: ``$($plan.CurrentTag)```n- Latest compatible: ``$($plan.LatestCompatibleTag)```n- State: ``$($plan.State)``"

if ($CurrentLauncher -and
    [string]$plan.LatestCompatibleTag -cne $RequestedTargetTag) {
    throw "Current-launcher plan did not resolve the exact requested target '$RequestedTargetTag'."
}

if ($plan.State -eq 'BlockedManualReview') {
    throw "Protocol update requires manual review: $($plan.Diagnostics -join '; ')"
}
if ($plan.State -eq 'MajorUpgradeRequired') {
    throw "A new protocol major '$($plan.LatestAvailableTag)' requires a manual migration."
}
$releaseEvidence = $null
if ([string]$plan.LatestCompatibleTag -cne [string]$plan.CurrentTag -or
    [string]$currentMigrationPlan.State -ceq 'ChangesRequired') {
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
    if ($CurrentLauncher -and
        [string]$releaseEvidence.CommitSha -cne $RequestedTargetCommit) {
        throw 'Immutable release evidence differs from the current-launcher target binding.'
    }
}
if (@($plan.Operations).Count -eq 0) {
    Write-Host "Protocol update state: $($plan.State). No mutation required."
    exit 0
}

$create = @($plan.Operations | Where-Object {
    $_.Kind -cin @('CreateUpgrade', 'CreateMigration')
})
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
    $proposalKind = if ($null -ne $create[0].PSObject.Properties['ProposalKind']) {
        [string]$create[0].ProposalKind
    }
    elseif ([string]$create[0].Kind -ceq 'CreateMigration') {
        'MigrationReconciliation'
    }
    else { 'Update' }
    $migrationPlan = $script:ConsumerMigrationPlansByTag[$targetTag]
    if ($null -eq $migrationPlan -or
        [string]$migrationPlan.PlanSha256 -cnotmatch '^[0-9a-f]{64}$') {
        throw "Resolver target '$targetTag' lacks one deterministic consumer migration plan."
    }
    if ($proposalKind -ceq 'Update') {
        if (-not (Test-GitAncestor -RepositoryPath $sourcePath `
                -Ancestor $currentProtocolSha -Descendant $targetSha)) {
            throw "Target '$targetTag' is not a descendant of current protocol '$currentTag'."
        }
    }
    $createdBranch = [string]$create[0].Branch
    if ($null -ne (Get-RemoteBranchHead -Branch $createdBranch)) {
        throw "Reserved target branch '$createdBranch' already exists without a valid managed PR."
    }

    Invoke-Native -Command 'git' -Arguments @('switch', '-c', $createdBranch) | Out-Null
    $expectedManagedPaths = @(Stage-ManagedProposalTree `
        -Workspace $workspace -BaseCommit $baseHeadSha `
        -TargetProtocolSha $targetSha -SourcePath $sourcePath `
        -ProtocolPath $ProtocolPath -Assets $ManagedUpdaterAssets `
        -MigrationPlan $migrationPlan -ProposalKind $proposalKind)

    Invoke-Native -Command 'git' -Arguments @('config', 'user.name', 'github-actions[bot]') | Out-Null
    Invoke-Native -Command 'git' -Arguments @('config', 'user.email', '41898282+github-actions[bot]@users.noreply.github.com') | Out-Null
    $commitMessage = if ($proposalKind -ceq 'Update') {
        "Upgrade common protocol to $targetTag"
    }
    else { "Reconcile consumer state for $targetTag" }
    Invoke-Native -Command 'git' -Arguments @(
        'commit', '-m', $commitMessage
    ) | Out-Null
    $headSha = ((Invoke-Native -Command 'git' -Arguments @('rev-parse', 'HEAD')) -join '').Trim()
    Assert-CommittedManagedUpdate -ExpectedPaths $expectedManagedPaths `
        -BaseCommit $baseHeadSha -Commit $headSha `
        -TargetProtocolSha $targetSha -SourcePath $sourcePath `
        -ProtocolPath $ProtocolPath -Assets $ManagedUpdaterAssets `
        -MigrationPlan $migrationPlan -ProposalKind $proposalKind

    if ($CurrentLauncher) {
        Assert-RemoteDefaultBranchUnchanged -Repository $repository `
            -DefaultBranch $env:DEFAULT_BRANCH `
            -ExpectedHeadSha $RequestedBaseSha
    }
    $updateIssue = Ensure-ProtocolUpdateIssue -Repository $repository `
        -TargetTag $targetTag -ProtocolSha $targetSha -Branch $createdBranch `
        -ProposalKind $proposalKind `
        -MigrationPlanSha ([string]$migrationPlan.PlanSha256) `
        -TrustedActor $TrustedActor

    $pushSucceeded = $false
    $marker = ''
    try {
        if ($CurrentLauncher) {
            Assert-RemoteDefaultBranchUnchanged -Repository $repository `
                -DefaultBranch $env:DEFAULT_BRANCH `
                -ExpectedHeadSha $RequestedBaseSha
        }
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
        $markerKind = if ($proposalKind -ceq 'Update') {
            'update'
        }
        else { 'migration-reconciliation' }
        $marker = [ordered]@{
            schema = 2
            kind = $markerKind
            target = $targetTag
            protocolSha = $targetSha
            migrationPlanSha = [string]$migrationPlan.PlanSha256
            pathsSha = Get-MigrationPathSetSha256 -Paths $expectedManagedPaths
            head = $headSha
            repository = $repository
        } | ConvertTo-Json -Compress
        $supersededNumbers = @($plan.Operations | Where-Object Kind -eq 'ClosePullRequest' |
            ForEach-Object { "#$($_.PullRequestNumber)" })
        $supersedes = if ($supersededNumbers.Count -gt 0) { $supersededNumbers -join ', ' } else { 'none' }
        $proposalHeading = if ($proposalKind -ceq 'Update') {
            '## Automated protocol dependency update'
        }
        else { '## Automated consumer-state reconciliation' }
        $proposalTitle = if ($proposalKind -ceq 'Update') {
            "Upgrade common protocol to $targetTag"
        }
        else { "Reconcile consumer state for $targetTag" }
        $bodyLines = [System.Collections.Generic.List[string]]::new()
        foreach ($line in @(
            "<!-- meandai-protocol-update:$marker -->",
            $proposalHeading, '',
            "- Installed pin: ``$currentTag``",
            "- Target release: ``$targetTag``",
            "- Protocol commit: ``$targetSha``",
            "- Migration plan: ``$([string]$migrationPlan.PlanSha256)``",
            "- Managed paths: ``$($expectedManagedPaths -join ', ')``",
            "- Supersedes: $supersedes", '',
            'This draft is review-only and will never merge itself.', '',
            '## Maintainer gates', '',
            '- [ ] Read every intervening meAndAI changelog entry.',
            '- [ ] Review incompatible or newly mandatory rules.',
            '- [ ] Review every catalog-declared consumer migration in this proposal.',
            '- [ ] Review the managed updater asset changes when present.',
            '- [ ] Run project tests and complete DoR/DoD review.', '',
            "Tracking issue: #$($updateIssue.Number)"
        )) {
            $bodyLines.Add([string]$line)
        }
        $body = $bodyLines -join [Environment]::NewLine
        $url = (Invoke-GhPullRequestCreateWithBodyFile `
            -Base $env:DEFAULT_BRANCH -Head $createdBranch `
            -Title $proposalTitle -Body $body | Select-Object -Last 1).Trim()
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
            ProposalKind = $proposalKind
            MigrationPlanSha = [string]$migrationPlan.PlanSha256
        }
        Set-ProtocolUpdateIssuePullRequestLink -Repository $repository `
            -IssueNumber ([int]$updateIssue.number) `
            -PullRequestNumber ([int]$createdPullRequest.number) -HeadSha $headSha
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
        $replacementProposalKind = if (
            [string]$plan.CurrentTag -ceq [string]$plan.LatestCompatibleTag -and
            [bool]$snapshot.MigrationRequired
        ) {
            'MigrationReconciliation'
        }
        else { 'Update' }
        $existingReplacements = @(Get-ExistingReplacementCandidates `
            -Candidates @($candidates) `
            -TargetTag ([string]$plan.LatestCompatibleTag) `
            -ProposalKind $replacementProposalKind `
            -MigrationPlanSha ([string]$snapshot.CurrentMigrationPlanSha) `
            -CurrentLauncherMode ([bool]$CurrentLauncher) `
            -BranchPrefix $BranchPrefix `
            -RecoveryBranchSuffix $RecoveryBranchSuffix)
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
            ProposalKind = [string]$replacement.Kind
            MigrationPlanSha = [string]$replacement.MigrationPlanSha
        }
    }
}

$deleteOperations = @($plan.Operations | Where-Object Kind -eq 'DeleteBranch')
$closeOperations = @($plan.Operations | Where-Object Kind -eq 'ClosePullRequest')
if ($CurrentLauncher -and $closeOperations.Count -gt 0) {
    Assert-RemoteDefaultBranchUnchanged -Repository $repository `
        -DefaultBranch $env:DEFAULT_BRANCH `
        -ExpectedHeadSha $RequestedBaseSha
}
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
    Complete-SupersededProtocolUpdateIssue -Repository $repository `
        -Operation $operation `
        -ReplacementPullRequestNumber $(if ($null -ne $replacementPullRequestNumber) {
            [int]$replacementPullRequestNumber
        } else { 0 })
    $comment = if ($null -ne $replacementPullRequestNumber) {
        "Superseded by #$replacementPullRequestNumber, the verified ``$($plan.LatestCompatibleTag)`` protocol proposal. Automated cleanup closed this PR and deleted its unchanged branch using an exact-head lease."
    }
    else {
        "The default branch already contains ``$($operation.TargetTag)``. Automated cleanup closed this PR and deleted its unchanged branch using an exact-head lease."
    }
    Invoke-GhMutationWithBodyFile -Method POST `
        -Endpoint "repos/$repository/issues/$($operation.PullRequestNumber)/comments" `
        -Body $comment | Out-Null
}

Write-Host "Protocol update reconciliation completed: $($plan.State)."
