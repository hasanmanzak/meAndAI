[CmdletBinding()]
param(
    [string]$TargetPath = '.',
    [string]$Owner = '',
    [string]$RepositoryName = '',
    [ValidateSet('private', 'public', 'internal')]
    [string]$Visibility = 'private',
    [string]$ProtocolRepository = 'hasanmanzak/meAndAI',
    [string]$ProtocolTag = 'v0.6.0',
    [string]$RemoteName = 'origin',
    [ValidateRange(1, 60)]
    [int]$WorkflowTimeoutMinutes = 15,
    [switch]$SkipLifecycleDispatch,
    [switch]$SkipCodexDelegation
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$workflowSourcePath = 'templates/project/.github/workflows/meandai-protocol-update.yml'
$workflowTargetPath = '.github/workflows/meandai-protocol-update.yml'
$tokenMappings = [ordered]@{
    'FG_PAT.txt' = 'MEANDAI_UPDATER_TOKEN'
    'MEANDAI_RO_FG_PAT.txt' = 'MEANDAI_PROTOCOL_TOKEN'
}

function Invoke-External {
    param(
        [Parameter(Mandatory)][string]$Command,
        [string[]]$Arguments = @(),
        [switch]$AllowFailure
    )

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $global:LASTEXITCODE = 0
        $output = @(& $Command @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) {
            $exitCode = 0
        }
    }
    finally {
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

    foreach ($name in $tokenMappings.Keys) {
        $path = Join-Path $Repository $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Required local credential file '$name' is missing from the target root."
        }

        $tracked = Invoke-Git -Repository $Repository -Arguments @(
            'ls-files', '--error-unmatch', '--', $name
        ) -AllowFailure
        if ($tracked.ExitCode -eq 0) {
            throw "Credential file '$name' is tracked or staged. Remove it from Git, rotate that token, and rerun."
        }

        $head = Invoke-Git -Repository $Repository -Arguments @('rev-parse', '--verify', 'HEAD') -AllowFailure
        if ($head.ExitCode -eq 0) {
            $history = Invoke-Git -Repository $Repository -Arguments @(
                'log', '--all', '--format=%H', '--', $name
            ) -AllowFailure
            if ($history.ExitCode -eq 0 -and (@($history.Output) -join '').Trim()) {
                throw "Credential file '$name' appears in repository history. Rotate that token and clean the history before rerunning."
            }
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
        'X-GitHub-Api-Version' = '2022-11-28'
        'User-Agent' = 'meAndAI-quick-adoption'
    }
    try {
        return Invoke-RestMethod -Method Get -Uri $Uri -Headers $headers
    }
    catch {
        throw "GitHub API access failed for the requested repository resource. Verify token scope and repository access, then rerun."
    }
}

function Get-CanonicalWorkflow {
    param([Parameter(Mandatory)][string]$ProtocolToken)

    if ($ProtocolRepository -cnotmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        throw "ProtocolRepository '$ProtocolRepository' must use the owner/repository form."
    }
    if ($ProtocolTag -cnotmatch '^v\d+\.\d+\.\d+$') {
        throw 'ProtocolTag must use the vM.m.rev form.'
    }

    $escapedRef = [Uri]::EscapeDataString($ProtocolTag)
    $uri = "https://api.github.com/repos/$ProtocolRepository/contents/$workflowSourcePath`?ref=$escapedRef"
    $response = Invoke-GitHubApi -Uri $uri -Token $ProtocolToken
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
    $global:LASTEXITCODE = 0
    $Value | & gh secret set $Name --repo $Repository 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to store repository Actions secret '$Name'."
    }
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
    $dispatchStarted = [DateTimeOffset]::UtcNow.AddSeconds(-5)
    $dispatched = $false
    for ($attempt = 1; $attempt -le 6; $attempt++) {
        # gh workflow run is retried briefly because a newly pushed workflow may need registration time.
        $dispatch = Invoke-External -Command 'gh' -Arguments @(
            'workflow', 'run', $workflowName, '--repo', $Repository, '--ref', $Branch
        ) -AllowFailure
        if ($dispatch.ExitCode -eq 0) {
            $dispatched = $true
            break
        }
        if ($attempt -lt 6) {
            Start-Sleep -Seconds 5
        }
    }
    if (-not $dispatched) {
        throw 'The lifecycle workflow was published but could not be dispatched after six bounded attempts.'
    }

    $deadline = [DateTimeOffset]::UtcNow.AddMinutes($WorkflowTimeoutMinutes)
    while ([DateTimeOffset]::UtcNow -lt $deadline) {
        $list = Invoke-External -Command 'gh' -Arguments @(
            'run', 'list', '--repo', $Repository, '--workflow', $workflowName,
            '--event', 'workflow_dispatch', '--branch', $Branch, '--commit', $HeadSha,
            '--limit', '10', '--json', 'databaseId,createdAt,headSha,status,conclusion,url'
        )
        try {
            $runs = @(((@($list.Output) -join [Environment]::NewLine) | ConvertFrom-Json))
        }
        catch {
            throw 'GitHub CLI returned invalid workflow-run metadata.'
        }
        $run = @($runs | Where-Object {
            $_.headSha -ceq $HeadSha -and
            [DateTimeOffset]::Parse([string]$_.createdAt) -ge $dispatchStarted
        } | Sort-Object { [DateTimeOffset]::Parse([string]$_.createdAt) } -Descending |
            Select-Object -First 1)
        if ($run.Count -eq 1 -and $run[0].status -ceq 'completed') {
            if ($run[0].conclusion -cne 'success') {
                throw "The lifecycle workflow completed with '$($run[0].conclusion)': $($run[0].url)"
            }
            return $run[0]
        }
        Start-Sleep -Seconds 5
    }

    throw "The lifecycle workflow did not complete within $WorkflowTimeoutMinutes minute(s)."
}

function Get-AdoptionPullRequest {
    param([Parameter(Mandatory)][string]$Repository)

    $branch = "automation/meandai-capabilities-$ProtocolTag"
    for ($attempt = 1; $attempt -le 6; $attempt++) {
        $list = Invoke-External -Command 'gh' -Arguments @(
            'pr', 'list', '--repo', $Repository, '--state', 'open', '--head', $branch,
            '--limit', '10', '--json', 'number,url,isDraft,headRefName'
        )
        try {
            $pullRequests = @(((@($list.Output) -join [Environment]::NewLine) | ConvertFrom-Json))
        }
        catch {
            throw 'GitHub CLI returned invalid adoption pull-request metadata.'
        }
        $matches = @($pullRequests | Where-Object { $_.headRefName -ceq $branch })
        if ($matches.Count -eq 1) {
            if (-not [bool]$matches[0].isDraft) {
                throw 'The deterministic adoption pull request is unexpectedly not a draft.'
            }
            return $matches[0]
        }
        if ($matches.Count -gt 1) {
            throw 'More than one open deterministic adoption pull request was found.'
        }
        if ($attempt -lt 6) {
            Start-Sleep -Seconds 5
        }
    }

    return $null
}

function Send-CodexAdoptionDelegation {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][int]$PullRequestNumber
    )

    $marker = '<!-- meandai-codex-adoption-v1 -->'
    $view = Invoke-External -Command 'gh' -Arguments @(
        'pr', 'view', [string]$PullRequestNumber, '--repo', $Repository, '--json', 'comments'
    )
    try {
        $pullRequest = ((@($view.Output) -join [Environment]::NewLine) | ConvertFrom-Json)
    }
    catch {
        throw 'GitHub CLI returned invalid pull-request comment metadata.'
    }
    if (@($pullRequest.comments | Where-Object { ([string]$_.body).Contains($marker) }).Count -gt 0) {
        return $false
    }

    $prompt = @"
@codex Complete this consumer repository's meAndAI AI-capabilities adoption on the current pull-request branch.

Read AGENTS.md, the pinned .ai/protocol/PROTOCOL.md, and .ai/adoption/meandai-capabilities.json before editing. Preserve project semantics; resolve every manifest collision deliberately; create or reconcile the required local memory, feature and decision records, tests, links, templates, and Agile labels; then remove the manifest.

Do not invent project facts, expose credentials, overwrite consumer-owned files mechanically, or enter an unbounded validation loop. Satisfy DoR, decompose material work, self-review each slice, run relevant tests, perform the bounded final scan, and push the completed changes to this pull-request branch. Do not merge. When every gate is satisfied, mark the pull request ready if your GitHub permissions allow it and leave concise test evidence; otherwise report the exact blocker.

$marker
"@
    $promptPath = [IO.Path]::GetTempFileName()
    try {
        [IO.File]::WriteAllText($promptPath, $prompt, [Text.UTF8Encoding]::new($false))
        # gh pr comment uses a body file so the task prompt is not a shell argument.
        Invoke-External -Command 'gh' -Arguments @(
            'pr', 'comment', [string]$PullRequestNumber, '--repo', $Repository,
            '--body-file', $promptPath
        ) | Out-Null
    }
    finally {
        if (Test-Path -LiteralPath $promptPath) {
            Remove-Item -LiteralPath $promptPath -Force
        }
    }
    return $true
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
Assert-TokenFilesAreLocalOnly -Repository $target

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

$protocolToken = Read-LocalToken -Path (Join-Path $target 'MEANDAI_RO_FG_PAT.txt')
$workflowBytes = Get-CanonicalWorkflow -ProtocolToken $protocolToken

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

$updaterToken = Read-LocalToken -Path (Join-Path $target 'FG_PAT.txt')
try {
    $targetInfo = Invoke-GitHubApi -Uri "https://api.github.com/repos/$repository" -Token $updaterToken
    if (-not ([string]$targetInfo.full_name).Equals($repository, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'identity mismatch'
    }
}
catch {
    throw "The updater token cannot access '$repository'. Add this repository to the token's selected-repository grant, then rerun."
}

$workflowFullPath = Join-Path $target ($workflowTargetPath -replace '/', [IO.Path]::DirectorySeparatorChar)
[void](Write-CanonicalWorkflow -Path $workflowFullPath -Bytes $workflowBytes)

foreach ($entry in $tokenMappings.GetEnumerator()) {
    $value = if ($entry.Key -ceq 'FG_PAT.txt') { $updaterToken } else { $protocolToken }
    Set-RepositorySecret -Repository $repository -Name $entry.Value -Value $value
}

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
Write-Host 'Both repository Actions secrets were reconciled before publication.'

if ($SkipLifecycleDispatch) {
    Write-Host 'Lifecycle dispatch was explicitly skipped. Run the meAndAI AI capabilities lifecycle workflow before adoption.'
}
else {
    $publishedHead = ((@(Invoke-Git -Repository $target -Arguments @(
        'rev-parse', 'HEAD'
    )).Output -join '').Trim())
    $run = Invoke-LifecycleWorkflow -Repository $repository -Branch $defaultBranch -HeadSha $publishedHead
    Write-Host "Lifecycle workflow completed successfully: $($run.url)"

    $adoptionPullRequest = Get-AdoptionPullRequest -Repository $repository
    if ($null -eq $adoptionPullRequest) {
        Write-Host 'No open deterministic adoption draft was produced; inspect the successful lifecycle run before continuing.'
    }
    else {
        Write-Host "Adoption draft: $($adoptionPullRequest.url)"
        if ($SkipCodexDelegation) {
            Write-Host 'Codex Cloud delegation was explicitly skipped; use the quick-guide prompt on this draft.'
        }
        else {
            $delegated = Send-CodexAdoptionDelegation -Repository $repository -PullRequestNumber $adoptionPullRequest.number
            if ($delegated) {
                Write-Host 'Codex Cloud adoption task was requested on the draft. Wait for its completion and review the evidence before merging.'
            }
            else {
                Write-Host 'The draft already contains the meAndAI Codex delegation marker; no duplicate task was requested.'
            }
        }
    }
}

Write-Host 'The launcher never approves or merges the adoption pull request.'
