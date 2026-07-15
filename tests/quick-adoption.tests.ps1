[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$launcherPath = Join-Path $root 'scripts/Invoke-MeAndAIQuickAdoption.ps1'
$guidePath = Join-Path $root 'docs/quick-adoption.md'
$workflowPath = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
$workflowRelativePath = '.github/workflows/meandai-protocol-update.yml'
$failures = [System.Collections.Generic.List[string]]::new()
$tempRoots = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Invoke-Git {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & git -C $Repository @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -ne 0) {
        throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    return @($output)
}

function New-TempRoot {
    param([string]$Name)

    $path = Join-Path ([IO.Path]::GetTempPath()) "meandai-quick-$Name-$([guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    $tempRoots.Add($path)
    return $path
}

function Set-TestGitIdentity {
    param([string]$Repository)

    Invoke-Git -Repository $Repository -Arguments @('config', 'user.name', 'meAndAI Test') | Out-Null
    Invoke-Git -Repository $Repository -Arguments @('config', 'user.email', 'meandai-test@example.invalid') | Out-Null
    Invoke-Git -Repository $Repository -Arguments @('config', 'commit.gpgsign', 'false') | Out-Null
    Invoke-Git -Repository $Repository -Arguments @('config', 'core.autocrlf', 'false') | Out-Null
}

function Get-GitBlobSha {
    param([byte[]]$Bytes)

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

function Reset-Mocks {
    $global:QuickAdoptionGhCalls = [System.Collections.Generic.List[object]]::new()
    $global:QuickAdoptionSecrets = [System.Collections.Generic.List[object]]::new()
    $global:QuickAdoptionRepoName = ''
    $global:QuickAdoptionDefaultBranch = 'main'
    $global:QuickAdoptionOwner = 'test-owner'
    $global:QuickAdoptionNewRemote = ''
    $global:QuickAdoptionTargetPath = ''
    $global:QuickAdoptionDenyTargetAccess = $false
    $global:QuickAdoptionComments = [System.Collections.Generic.List[string]]::new()
    $global:QuickAdoptionRunListCalls = 0
    $global:QuickAdoptionPrListCalls = 0
    $global:QuickAdoptionWorkflowBytes = [IO.File]::ReadAllBytes($workflowPath)
    $global:QuickAdoptionWorkflowSha = Get-GitBlobSha -Bytes $global:QuickAdoptionWorkflowBytes
}

function global:Invoke-RestMethod {
    [CmdletBinding()]
    param(
        [string]$Uri,
        [hashtable]$Headers,
        [string]$Method = 'Get'
    )

    if ($Uri -match '/contents/templates/project/\.github/workflows/meandai-protocol-update\.yml\?ref=v0\.6\.0$') {
        return [pscustomobject]@{
            content = [Convert]::ToBase64String($global:QuickAdoptionWorkflowBytes)
            encoding = 'base64'
            sha = $global:QuickAdoptionWorkflowSha
        }
    }

    if ($Uri -match '/repos/[^/]+/[^/]+$') {
        if ($global:QuickAdoptionDenyTargetAccess) {
            throw 'Mock selected-repository grant does not include the target.'
        }
        return [pscustomobject]@{ full_name = $global:QuickAdoptionRepoName }
    }

    throw "Unexpected Invoke-RestMethod call: $Method $Uri"
}

function global:gh {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(ValueFromPipeline = $true)][string]$InputValue,
        [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
    )

    $stdin = if ($PSBoundParameters.ContainsKey('InputValue')) {
        $InputValue
    }
    else {
        (@($input) -join [Environment]::NewLine)
    }
    $global:QuickAdoptionGhCalls.Add([pscustomobject]@{
        Arguments = @($Arguments)
        Stdin = $stdin
    })

    $joined = $Arguments -join ' '
    if ($joined -eq 'auth status') {
        return
    }
    if ($joined -eq 'api user --jq .login') {
        return $global:QuickAdoptionOwner
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'repo' -and $Arguments[1] -eq 'view') {
        return (@{
            nameWithOwner = $global:QuickAdoptionRepoName
            defaultBranchRef = @{ name = $global:QuickAdoptionDefaultBranch }
        } | ConvertTo-Json -Compress)
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'repo' -and $Arguments[1] -eq 'create') {
        & git init --bare $global:QuickAdoptionNewRemote 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to create the fake bare GitHub remote.'
        }
        Invoke-Git -Repository $global:QuickAdoptionTargetPath -Arguments @(
            'config', "url.$($global:QuickAdoptionNewRemote.Replace('\\', '/')).insteadOf",
            "https://github.com/$($global:QuickAdoptionRepoName).git"
        ) | Out-Null
        Invoke-Git -Repository $global:QuickAdoptionTargetPath -Arguments @(
            'remote', 'add', 'origin', "https://github.com/$($global:QuickAdoptionRepoName).git"
        ) | Out-Null
        return
    }
    if ($Arguments.Count -ge 3 -and $Arguments[0] -eq 'secret' -and $Arguments[1] -eq 'set') {
        $global:QuickAdoptionSecrets.Add([pscustomobject]@{
            Name = $Arguments[2]
            Value = $stdin
            Arguments = @($Arguments)
        })
        return
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'workflow' -and $Arguments[1] -eq 'run') {
        return
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'run' -and $Arguments[1] -eq 'list') {
        $global:QuickAdoptionRunListCalls++
        if ($global:QuickAdoptionRunListCalls -gt 2) {
            throw 'Mock completed workflow was polled more than twice.'
        }
        $commitIndex = [Array]::IndexOf([object[]]$Arguments, '--commit')
        if ($commitIndex -lt 0 -or $commitIndex + 1 -ge $Arguments.Count) {
            throw 'Mock run list did not receive the published commit filter.'
        }
        $head = $Arguments[$commitIndex + 1]
        return (@([ordered]@{
            databaseId = 7001
            createdAt = [DateTimeOffset]::UtcNow.ToString('o')
            headSha = $head
            status = 'completed'
            conclusion = 'success'
            url = 'https://github.com/test-owner/consumer/actions/runs/7001'
        }) | ConvertTo-Json -Compress)
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'pr' -and $Arguments[1] -eq 'list') {
        $global:QuickAdoptionPrListCalls++
        if ($global:QuickAdoptionPrListCalls -gt 2) {
            throw 'Mock deterministic pull request was queried more than twice.'
        }
        return (@([ordered]@{
            number = 42
            url = "https://github.com/$($global:QuickAdoptionRepoName)/pull/42"
            isDraft = $true
            headRefName = 'automation/meandai-capabilities-v0.6.0'
        }) | ConvertTo-Json -Compress)
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'pr' -and $Arguments[1] -eq 'view') {
        $comments = @($global:QuickAdoptionComments | ForEach-Object { @{ body = $_ } })
        return (@{ comments = $comments } | ConvertTo-Json -Depth 4 -Compress)
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'pr' -and $Arguments[1] -eq 'comment') {
        $bodyIndex = [Array]::IndexOf([object[]]$Arguments, '--body-file')
        if ($bodyIndex -lt 0 -or $bodyIndex + 1 -ge $Arguments.Count) {
            throw 'Mock PR comment did not receive a body file.'
        }
        $global:QuickAdoptionComments.Add([IO.File]::ReadAllText($Arguments[$bodyIndex + 1]))
        return
    }

    throw "Unexpected gh call: $joined"
}

try {
    foreach ($requiredPath in @($launcherPath, $guidePath, $workflowPath)) {
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            Add-Failure "TEST-0033 missing required quick-adoption asset: $requiredPath"
        }
    }

    if (Test-Path -LiteralPath $launcherPath -PathType Leaf) {
        $launcher = Get-Content -LiteralPath $launcherPath -Raw
        $tokens = $null
        $parseErrors = $null
        [void][Management.Automation.Language.Parser]::ParseFile(
            $launcherPath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        if (@($parseErrors).Count -gt 0) {
            Add-Failure "TEST-0033 launcher has PowerShell parse errors: $($parseErrors -join '; ')"
        }

        foreach ($required in @(
            'v0.6.0',
            'FG_PAT.txt',
            'MEANDAI_RO_FG_PAT.txt',
            'MEANDAI_UPDATER_TOKEN',
            'MEANDAI_PROTOCOL_TOKEN',
            'templates/project/.github/workflows/meandai-protocol-update.yml',
            '.github/workflows/meandai-protocol-update.yml',
            'Invoke-RestMethod',
            'gh secret set',
            'info/exclude',
            '--private',
            'workflow run',
            'WorkflowTimeoutMinutes',
            'SkipLifecycleDispatch',
            'SkipCodexDelegation',
            '@codex',
            '--body-file',
            'meandai-codex-adoption-v1'
        )) {
            if (-not $launcher.Contains($required)) {
                Add-Failure "TEST-0033 launcher is missing '$required'"
            }
        }
        if ($launcher -match '[''"]--body[''"]') {
            Add-Failure "TEST-0033 launcher contains forbidden secret body argument '--body'"
        }
        foreach ($forbidden in @('gh pr merge', 'git add -A', 'git add .')) {
            if ($launcher.Contains($forbidden)) {
                Add-Failure "TEST-0033 launcher contains forbidden behavior '$forbidden'"
            }
        }
    }

    if (Test-Path -LiteralPath $guidePath -PathType Leaf) {
        $guide = Get-Content -LiteralPath $guidePath -Raw
        foreach ($required in @(
            'v0.6.0',
            'FG_PAT.txt',
            'MEANDAI_RO_FG_PAT.txt',
            'MEANDAI_UPDATER_TOKEN',
            'MEANDAI_PROTOCOL_TOKEN',
            'Invoke-MeAndAIQuickAdoption.ps1',
            '.ai/adoption/meandai-capabilities.json',
            'dispatches the lifecycle workflow',
            'Codex Cloud',
            '@codex',
            'selected-repository',
            'Codex prompt',
            'Quick command'
        )) {
            if (-not $guide.Contains($required)) {
                Add-Failure "TEST-0037 quick guide is missing '$required'"
            }
        }
    }

    if ($failures.Count -eq 0) {
        Reset-Mocks
        $existingRoot = New-TempRoot -Name 'existing'
        $existingRepo = Join-Path $existingRoot 'consumer'
        $existingRemote = Join-Path $existingRoot 'consumer.git'
        New-Item -ItemType Directory -Path $existingRepo | Out-Null
        & git init --bare $existingRemote 2>&1 | Out-Null
        & git init -b main $existingRepo 2>&1 | Out-Null
        Set-TestGitIdentity -Repository $existingRepo
        Set-Content -LiteralPath (Join-Path $existingRepo 'app.txt') -Value 'consumer-app' -Encoding UTF8
        Invoke-Git -Repository $existingRepo -Arguments @('add', 'app.txt') | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('commit', '-m', 'Initial consumer') | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @(
            'config', "url.$($existingRemote.Replace('\\', '/')).insteadOf",
            'https://github.com/test-owner/consumer.git'
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @(
            'remote', 'add', 'origin', 'https://github.com/test-owner/consumer.git'
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('push', '-u', 'origin', 'main') | Out-Null
        Set-Content -LiteralPath (Join-Path $existingRepo 'FG_PAT.txt') -Value 'write-token-value' -NoNewline
        Set-Content -LiteralPath (Join-Path $existingRepo 'MEANDAI_RO_FG_PAT.txt') -Value 'read-token-value' -NoNewline
        $global:QuickAdoptionRepoName = 'test-owner/consumer'
        $global:QuickAdoptionTargetPath = $existingRepo

        $runOutput = @(& $launcherPath -TargetPath $existingRepo 2>&1) -join [Environment]::NewLine
        if ($global:QuickAdoptionSecrets.Count -ne 2 -or
            @($global:QuickAdoptionSecrets.Name) -notcontains 'MEANDAI_UPDATER_TOKEN' -or
            @($global:QuickAdoptionSecrets.Name) -notcontains 'MEANDAI_PROTOCOL_TOKEN') {
            Add-Failure 'TEST-0034 existing adoption did not reconcile both required secrets.'
        }
        foreach ($secret in $global:QuickAdoptionSecrets) {
            if ($secret.Arguments -contains '--body') {
                Add-Failure 'TEST-0033 secret value was eligible for command-line transfer.'
            }
        }
        if ($runOutput.Contains('write-token-value') -or $runOutput.Contains('read-token-value')) {
            Add-Failure 'TEST-0033 launcher output exposed a token value.'
        }
        $dispatchCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -eq 'workflow' -and $_.Arguments[1] -eq 'run'
        })
        if ($dispatchCalls.Count -ne 1 -or $global:QuickAdoptionComments.Count -ne 1 -or
            -not $global:QuickAdoptionComments[0].Contains('@codex') -or
            -not $global:QuickAdoptionComments[0].Contains('.ai/adoption/meandai-capabilities.json')) {
            Add-Failure 'TEST-0037 default adoption did not dispatch once and create one scoped Codex Cloud handoff.'
        }

        $remotePaths = @(Invoke-Git -Repository $existingRepo -Arguments @(
            'ls-tree', '-r', '--name-only', 'origin/main'
        ))
        $expectedPaths = @($workflowRelativePath, 'app.txt') | Sort-Object
        if ((@($remotePaths | Sort-Object) -join '|') -cne ($expectedPaths -join '|')) {
            Add-Failure "TEST-0034 existing remote has unexpected paths: $($remotePaths -join ', ')"
        }
        $status = @(Invoke-Git -Repository $existingRepo -Arguments @('status', '--short'))
        if ($status.Count -ne 0) {
            Add-Failure "TEST-0034 existing repository is not clean after adoption: $($status -join ', ')"
        }

        $global:QuickAdoptionRunListCalls = 0
        $global:QuickAdoptionPrListCalls = 0
        $headBeforeRerun = (Invoke-Git -Repository $existingRepo -Arguments @('rev-parse', 'HEAD'))[0]
        & $launcherPath -TargetPath $existingRepo | Out-Null
        $headAfterRerun = (Invoke-Git -Repository $existingRepo -Arguments @('rev-parse', 'HEAD'))[0]
        if ($headBeforeRerun -cne $headAfterRerun) {
            Add-Failure 'TEST-0036 exact rerun created a duplicate commit.'
        }
        if ($global:QuickAdoptionComments.Count -ne 1) {
            Add-Failure 'TEST-0036 exact rerun requested a duplicate Codex Cloud task.'
        }

        $secretCountBeforeDrift = $global:QuickAdoptionSecrets.Count
        Set-Content -LiteralPath (Join-Path $existingRepo $workflowRelativePath) -Value 'workflow-drift' -Encoding UTF8
        $driftBlocked = $false
        try {
            & $launcherPath -TargetPath $existingRepo | Out-Null
        }
        catch {
            $driftBlocked = $true
        }
        if (-not $driftBlocked -or $global:QuickAdoptionSecrets.Count -ne $secretCountBeforeDrift) {
            Add-Failure 'TEST-0036 workflow drift did not block before secret mutation.'
        }
        Invoke-Git -Repository $existingRepo -Arguments @('restore', $workflowRelativePath) | Out-Null

        Invoke-Git -Repository $existingRepo -Arguments @('add', '-f', '--', 'FG_PAT.txt') | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('commit', '-m', 'Expose test credential path') | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('push', 'origin', 'main') | Out-Null
        $secretCountBeforeTracked = $global:QuickAdoptionSecrets.Count
        $trackedTokenBlocked = $false
        try {
            & $launcherPath -TargetPath $existingRepo -SkipLifecycleDispatch | Out-Null
        }
        catch {
            $trackedTokenBlocked = $true
        }
        if (-not $trackedTokenBlocked -or
            $global:QuickAdoptionSecrets.Count -ne $secretCountBeforeTracked) {
            Add-Failure 'TEST-0036 tracked token file did not block before secret mutation.'
        }

        Reset-Mocks
        $newRoot = New-TempRoot -Name 'new'
        $newRepo = Join-Path $newRoot 'new-consumer'
        $newRemote = Join-Path $newRoot 'new-consumer.git'
        New-Item -ItemType Directory -Path (Join-Path $newRepo 'src') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $newRepo 'src/app.txt') -Value 'local-only' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $newRepo 'FG_PAT.txt') -Value 'new-write-token' -NoNewline
        Set-Content -LiteralPath (Join-Path $newRepo 'MEANDAI_RO_FG_PAT.txt') -Value 'new-read-token' -NoNewline
        $global:QuickAdoptionRepoName = 'test-owner/new-consumer'
        $global:QuickAdoptionTargetPath = $newRepo
        $global:QuickAdoptionNewRemote = $newRemote

        $global:QuickAdoptionDenyTargetAccess = $true
        $grantBlocked = $false
        try {
            & $launcherPath -TargetPath $newRepo -SkipLifecycleDispatch | Out-Null
        }
        catch {
            $grantBlocked = $true
        }
        if (-not $grantBlocked -or $global:QuickAdoptionSecrets.Count -ne 0) {
            Add-Failure 'TEST-0036 missing selected-repository grant did not block before secret storage.'
        }
        $global:QuickAdoptionDenyTargetAccess = $false
        & $launcherPath -TargetPath $newRepo -SkipLifecycleDispatch | Out-Null
        $createCall = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -eq 'repo' -and $_.Arguments[1] -eq 'create'
        })
        if ($createCall.Count -ne 1 -or $createCall[0].Arguments -notcontains '--private') {
            Add-Failure 'TEST-0035 new adoption did not create one private repository.'
        }
        $newRemotePaths = @(Invoke-Git -Repository $newRepo -Arguments @(
            'ls-tree', '-r', '--name-only', 'origin/main'
        ))
        if ($newRemotePaths.Count -ne 1 -or $newRemotePaths[0] -cne $workflowRelativePath) {
            Add-Failure "TEST-0035 new remote published unrelated paths: $($newRemotePaths -join ', ')"
        }
        $newStatus = @(Invoke-Git -Repository $newRepo -Arguments @('status', '--short'))
        if ($newStatus.Count -ne 1 -or $newStatus[0] -notmatch '^\?\? src/') {
            Add-Failure "TEST-0035 unrelated local content was not preserved as untracked: $($newStatus -join ', ')"
        }
    }
}
catch {
    Add-Failure "Quick-adoption test harness failed: $($_.Exception.Message)"
}
finally {
    Remove-Item Function:\global:gh -ErrorAction SilentlyContinue
    Remove-Item Function:\global:Invoke-RestMethod -ErrorAction SilentlyContinue
    foreach ($path in $tempRoots) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Quick-adoption tests failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Quick-adoption tests passed: TEST-0033 through TEST-0037.' -ForegroundColor Green
