[CmdletBinding()]
param(
    [string]$TargetPath = '.',
    [string]$Owner = '',
    [string]$RepositoryName = '',
    [ValidateSet('private', 'public', 'internal')]
    [string]$Visibility = 'private',
    [string]$ProtocolRepository = 'hasanmanzak/meAndAI',
    [string]$ProtocolTag = 'v0.6.1',
    [string]$RemoteName = 'origin',
    [ValidateRange(1, 60)]
    [int]$WorkflowTimeoutMinutes = 15,
    [ValidateRange(1, 120)]
    [int]$CodexTimeoutMinutes = 30,
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
    [pscustomobject]@{ Name = 'status:needs-review'; Color = '5319e7'; Description = 'Ready for maintainer review' }
)

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
            '--limit', '10', '--json', 'number,url,isDraft,headRefName,headRefOid'
        )
        try {
            $pullRequests = @(((@($list.Output) -join [Environment]::NewLine) | ConvertFrom-Json))
        }
        catch {
            throw 'GitHub CLI returned invalid adoption pull-request metadata.'
        }
        $matchingPullRequests = @($pullRequests | Where-Object { $_.headRefName -ceq $branch })
        if ($matchingPullRequests.Count -eq 1) {
            foreach ($property in @('number', 'url', 'isDraft', 'headRefName', 'headRefOid')) {
                if ($null -eq $matchingPullRequests[0].PSObject.Properties[$property]) {
                    throw "The deterministic adoption pull request is missing '$property' metadata."
                }
            }
            if ([string]$matchingPullRequests[0].headRefOid -cnotmatch '^[0-9a-f]{40}$') {
                throw 'The deterministic adoption pull request has an invalid head commit.'
            }
            return $matchingPullRequests[0]
        }
        if ($matchingPullRequests.Count -gt 1) {
            throw 'More than one open deterministic adoption pull request was found.'
        }
        if ($attempt -lt 6) {
            Start-Sleep -Seconds 5
        }
    }

    return $null
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

function Ensure-AdoptionIssue {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$TemporaryDirectory
    )

    $marker = '<!-- meandai-local-adoption:{0}:pr-{1} -->' -f `
        $ProtocolTag, [string]$PullRequest.number
    $list = Invoke-External -Command 'gh' -Arguments @(
        'issue', 'list', '--repo', $Repository, '--state', 'all', '--limit', '1000',
        '--json', 'number,url,title,body,state'
    )
    try {
        $parsed = ((@($list.Output) -join [Environment]::NewLine) | ConvertFrom-Json)
        $issues = @($parsed | Where-Object { $null -ne $_ })
    }
    catch {
        throw 'GitHub CLI returned invalid adoption-issue metadata.'
    }
    $matchingIssues = @($issues | Where-Object {
        $null -ne $_.PSObject.Properties['body'] -and
        ([string]$_.body).Contains($marker)
    })
    if ($matchingIssues.Count -gt 1) {
        throw 'More than one project-owned adoption issue has the canonical marker.'
    }
    if ($matchingIssues.Count -eq 1) {
        $issue = $matchingIssues[0]
        if ([string]$issue.url -notmatch '^https://github\.com/[^/]+/[^/]+/issues/[1-9][0-9]*/?$' -or
            [int]$issue.number -le 0) {
            throw 'The project-owned adoption issue has invalid identity metadata.'
        }
        if ([string]$issue.state -ceq 'CLOSED') {
            Invoke-External -Command 'gh' -Arguments @(
                'issue', 'reopen', [string]$issue.number, '--repo', $Repository
            ) | Out-Null
        }
        Invoke-External -Command 'gh' -Arguments @(
            'issue', 'edit', [string]$issue.number, '--repo', $Repository,
            '--add-label', 'type:feature', '--add-label', 'priority:p1',
            '--add-label', 'status:needs-review'
        ) | Out-Null
        return $issue
    }

    $bodyPath = Join-Path $TemporaryDirectory 'adoption-issue.md'
    $body = @(
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
    [IO.File]::WriteAllText($bodyPath, $body + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
    $created = Invoke-External -Command 'gh' -Arguments @(
        'issue', 'create', '--repo', $Repository,
        '--title', "Track meAndAI AI capabilities adoption from $ProtocolTag",
        '--body-file', $bodyPath,
        '--label', 'type:feature', '--label', 'priority:p1',
        '--label', 'status:needs-review'
    )
    $url = ((@($created.Output) -join [Environment]::NewLine).Trim())
    if ($url -notmatch '^https://github\.com/[^/]+/[^/]+/issues/(?<number>[1-9][0-9]*)/?$') {
        throw 'Created adoption issue returned an unrecognized URL.'
    }
    return [pscustomobject]@{
        number = [int]$Matches.number
        url = $url
        title = "Track meAndAI AI capabilities adoption from $ProtocolTag"
        body = $body
        state = 'OPEN'
    }
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
        [Parameter(Mandatory)][ValidateRange(1, 120)][int]$TimeoutMinutes,
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
        $timeoutMilliseconds = [int][Math]::Min(
            [int]::MaxValue,
            [TimeSpan]::FromMinutes($TimeoutMinutes).TotalMilliseconds
        )
        if (-not $process.WaitForExit($timeoutMilliseconds)) {
            try {
                $process.Kill($true)
            }
            catch {
                if ($env:OS -eq 'Windows_NT') {
                    & "$env:SystemRoot\System32\taskkill.exe" /PID $process.Id /T /F 2>$null | Out-Null
                }
                else {
                    try { $process.Kill() } catch { }
                }
            }
            [void]$process.WaitForExit(5000)
            throw "$Operation exceeded the $TimeoutMinutes minute limit and was terminated."
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
        [Parameter(Mandatory)][int]$TimeoutMinutes
    )

    $result = Invoke-BoundedProcess -Runner $Runner -Arguments @('login', 'status') `
        -TimeoutMinutes $TimeoutMinutes -Operation 'Local Codex authentication check'
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
        [Parameter(Mandatory)][int]$TimeoutMinutes
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
        -StandardInput $Prompt -TimeoutMinutes $TimeoutMinutes `
        -Operation 'Local Codex adoption execution'
    if ($result.ExitCode -ne 0) {
        $detail = Get-ProcessFailureDetail -Result $result
        throw "Local Codex exited with code $($result.ExitCode). $detail"
    }
}

function Get-ProtocolSourceSnapshot {
    param(
        [Parameter(Mandatory)][string]$Token,
        [Parameter(Mandatory)][string]$Commit,
        [Parameter(Mandatory)][string]$Destination
    )

    if ($Commit -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The adoption manifest contains an invalid protocol commit.'
    }
    $archivePath = Join-Path $Destination 'protocol-source.zip'
    $extractPath = Join-Path $Destination 'protocol-source'
    [IO.Directory]::CreateDirectory($extractPath) | Out-Null
    $headers = @{
        Accept = 'application/vnd.github+json'
        Authorization = "Bearer $Token"
        'X-GitHub-Api-Version' = '2022-11-28'
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
    if ($roots.Count -ne 1 -or
        -not (Test-Path -LiteralPath (Join-Path $roots[0].FullName 'PROTOCOL.md') -PathType Leaf)) {
        throw 'The exact protocol source snapshot has an unexpected structure.'
    }
    $versionPath = Join-Path $roots[0].FullName 'VERSION'
    if (-not (Test-Path -LiteralPath $versionPath -PathType Leaf) -or
        [IO.File]::ReadAllText($versionPath).Trim() -cne $ProtocolTag.Substring(1)) {
        throw 'The protocol source snapshot version does not match the requested tag.'
    }
    return $roots[0].FullName
}

function Assert-CredentialFilesAbsent {
    param([Parameter(Mandatory)][string]$Repository)

    foreach ($name in $tokenMappings.Keys) {
        $matches = @(Get-ChildItem -LiteralPath $Repository -Recurse -Force -File -Filter $name)
        if ($matches.Count -gt 0) {
            throw "Credential file '$name' must not exist in the isolated Codex clone."
        }
    }
}

function Get-RemoteBranchHead {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Remote,
        [Parameter(Mandatory)][string]$Branch
    )

    $result = Invoke-Git -Repository $Repository -Arguments @(
        'ls-remote', '--heads', $Remote, "refs/heads/$Branch"
    )
    $lines = @($result.Output | Where-Object { $_ })
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

function Complete-AdoptionWithLocalCodex {
    param(
        [Parameter(Mandatory)][string]$TargetRepository,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$ProtocolToken
    )

    $branch = [string]$PullRequest.headRefName
    $expectedHead = [string]$PullRequest.headRefOid
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

        $manifestRelativePath = '.ai/adoption/meandai-capabilities.json'
        $manifestPath = Join-Path $clonePath `
            ($manifestRelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
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

        try {
            $manifest = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
        }
        catch {
            throw 'The adoption manifest is not valid JSON.'
        }
        if ([int]$manifest.schema -ne 1 -or
            [string]$manifest.operation -cne 'ai-capabilities-adoption' -or
            -not ([string]$manifest.repository).Equals($Repository, [StringComparison]::OrdinalIgnoreCase) -or
            [string]$manifest.targetTag -cne $ProtocolTag -or
            [string]$manifest.protocolSha -cnotmatch '^[0-9a-f]{40}$') {
            throw 'The adoption manifest identity does not match this repository and protocol release.'
        }

        $protocolSource = Get-ProtocolSourceSnapshot -Token $ProtocolToken `
            -Commit ([string]$manifest.protocolSha) -Destination $temporaryRoot

        Ensure-AdoptionLabels -Repository $Repository
        $adoptionIssue = Ensure-AdoptionIssue -Repository $Repository `
            -PullRequest $PullRequest -TemporaryDirectory $temporaryRoot

        $runner = Resolve-LocalCodexRunner -ExplicitCommand $CodexCommand `
            -FallbackVersion $TemporaryCodexVersion
        Assert-LocalCodexLogin -Runner $runner -TimeoutMinutes $CodexTimeoutMinutes

        $resultPath = Join-Path $temporaryRoot 'codex-result.txt'
        $prompt = @"
Complete the meAndAI AI-capabilities adoption for $Repository pull request #$($PullRequest.number) in this isolated temporary clone.

Read the manifest at .ai/adoption/meandai-capabilities.json, the exact protocol source at $protocolSource, every applicable AGENTS.md, and the consumer's existing project files before editing. Resolve collisions semantically; create or reconcile the project-owned feature and decision records, local memory, tests, evidence, and clickable links required by the protocol. The launcher already reconciled the required Agile labels and project-owned adoption issue $($adoptionIssue.url); reference that issue from the local feature record. Do not invent project facts; if required facts are unavailable, stop as blocked. If the .ai/protocol gitlink is absent, create it from $ProtocolRepository at exactly $($manifest.protocolSha); never substitute a moving ref.

Secret provisioning is already complete: FG_PAT.txt maps to MEANDAI_UPDATER_TOKEN and MEANDAI_RO_FG_PAT.txt maps to MEANDAI_PROTOCOL_TOKEN. Those source files are intentionally absent. Do not search for, request, print, recreate, or modify credential values or repository secrets.

Work only in this clone. Spawned-command network access is disabled: do not invoke gh, GitHub APIs, remote Git operations, or any other external service. Preserve any existing pinned protocol gitlink and do not change the lifecycle workflow. Do not commit, push, approve, mark the pull request ready, merge, close, delete, or alter branches. The launcher owns GitHub records and Git publication; the maintainer owns merge.

Keep validation bounded: implement reviewable slices, run relevant tests, perform one fresh-diff self-review and the protocol's bounded completion scan, fix blocking findings only, and avoid recursive validators. Remove .ai/adoption/meandai-capabilities.json only when all adoption gates are satisfied.

Your final response must start with MEANDAI_ADOPTION_READY only when the manifest has been removed and the repository-local adoption work is complete. Otherwise start with MEANDAI_ADOPTION_BLOCKED and state the exact blocker. Include concise test evidence.
"@
        Invoke-LocalCodexExec -Runner $runner -WorkingDirectory $clonePath `
            -Prompt $prompt -OutputPath $resultPath `
            -TimeoutMinutes $CodexTimeoutMinutes

        if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
            throw 'Local Codex completed without a final result file.'
        }
        $result = [IO.File]::ReadAllText($resultPath).Trim()
        if (-not $result.StartsWith('MEANDAI_ADOPTION_READY', [StringComparison]::Ordinal)) {
            if ($result.Length -gt 1200) { $result = $result.Substring(0, 1200) + '...' }
            throw "Local Codex did not declare the adoption ready. $result"
        }

        $headAfterCodex = ((@(Invoke-Git -Repository $clonePath -Arguments @(
            'rev-parse', 'HEAD'
        )).Output -join '').Trim())
        if ($headAfterCodex -cne $expectedHead) {
            throw 'Local Codex created a commit; the launcher will not publish an agent-owned history.'
        }
        if (Test-Path -LiteralPath $manifestPath) {
            throw 'Local Codex declared readiness but left the transient adoption manifest.'
        }
        Assert-CredentialFilesAbsent -Repository $clonePath
        Invoke-Git -Repository $clonePath -Arguments @('diff', '--check') | Out-Null

        Invoke-Git -Repository $clonePath -Arguments @('add', '-A') | Out-Null
        $changedPaths = @((Invoke-Git -Repository $clonePath -Arguments @(
            'diff', '--cached', '--name-only', '--diff-filter=ACMRTD'
        )).Output | Where-Object { $_ })
        if ($changedPaths.Count -eq 0) {
            throw 'Local Codex produced no reviewable adoption change.'
        }
        foreach ($forbiddenPath in @($workflowTargetPath) + @($tokenMappings.Keys)) {
            if ($changedPaths -ccontains $forbiddenPath) {
                throw "Local Codex changed protected adoption path '$forbiddenPath'."
            }
        }
        if (@($changedPaths | Where-Object { $_ -clike '.ai/protocol/*' }).Count -gt 0) {
            throw 'Local Codex changed files inside the protocol reference instead of preserving one gitlink.'
        }
        if ($changedPaths -ccontains '.ai/protocol') {
            $protocolIndex = ((@(Invoke-Git -Repository $clonePath -Arguments @(
                'ls-files', '--stage', '--', '.ai/protocol'
            )).Output -join '').Trim())
            $expectedProtocolIndex = "160000 $([string]$manifest.protocolSha) 0`t.ai/protocol"
            if ($protocolIndex -cne $expectedProtocolIndex) {
                throw 'The completed protocol reference is not the exact manifest gitlink.'
            }
            $gitmodulesPath = Join-Path $clonePath '.gitmodules'
            $protocolModulePath = ((@(Invoke-Git -Repository $clonePath -Arguments @(
                'config', '-f', $gitmodulesPath, '--get', 'submodule..ai/protocol.path'
            )).Output -join '').Trim())
            $protocolModuleUrl = ((@(Invoke-Git -Repository $clonePath -Arguments @(
                'config', '-f', $gitmodulesPath, '--get', 'submodule..ai/protocol.url'
            )).Output -join '').Trim())
            if ($protocolModulePath -cne '.ai/protocol' -or
                $protocolModuleUrl -cne "https://github.com/$ProtocolRepository.git") {
                throw 'The completed protocol submodule metadata is not canonical.'
            }
            $protocolWorktree = Join-Path $clonePath '.ai/protocol'
            $protocolHead = ((@(Invoke-Git -Repository $protocolWorktree -Arguments @(
                'rev-parse', 'HEAD'
            )).Output -join '').Trim())
            $protocolStatus = @((Invoke-Git -Repository $protocolWorktree -Arguments @(
                'status', '--porcelain=v1', '--untracked-files=all'
            )).Output | Where-Object { $_ })
            if ($protocolHead -cne [string]$manifest.protocolSha -or $protocolStatus.Count -ne 0) {
                throw 'The completed protocol submodule is not clean at the exact manifest commit.'
            }
        }
        Invoke-Git -Repository $clonePath -Arguments @('diff', '--cached', '--check') | Out-Null

        $liveHead = Get-RemoteBranchHead -Repository $clonePath -Remote 'origin' -Branch $branch
        if ($liveHead -cne $expectedHead) {
            throw 'The adoption branch changed while local Codex was running; no local result was published.'
        }

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
        Invoke-Git -Repository $clonePath -Arguments @(
            'push', 'origin',
            "--force-with-lease=refs/heads/$branch`:$expectedHead",
            "HEAD:refs/heads/$branch"
        ) | Out-Null
        $verifiedHead = Get-RemoteBranchHead -Repository $clonePath -Remote 'origin' -Branch $branch
        if ($verifiedHead -cne $publishedHead) {
            throw 'The adoption branch did not resolve to the launcher-published commit.'
        }

        Invoke-External -Command 'gh' -Arguments @(
            'pr', 'ready', [string]$PullRequest.number, '--repo', $Repository
        ) | Out-Null
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

    $adoptionPullRequestResults = @(Get-AdoptionPullRequest -Repository $repository)
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
                -ProtocolToken $protocolToken
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
