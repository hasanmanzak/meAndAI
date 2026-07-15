[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$launcherPath = Join-Path $root 'scripts/Invoke-MeAndAIQuickAdoption.ps1'
$guidePath = Join-Path $root 'docs/quick-adoption.md'
$workflowPath = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
$mockCodexScriptPath = Join-Path $root 'tests/fixtures/Invoke-MockCodex.ps1'
$mockCodexWindowsPath = Join-Path $root 'tests/fixtures/Invoke-MockCodex.cmd'
$mockCodexUnixPath = Join-Path $root 'tests/fixtures/Invoke-MockCodex.sh'
$mockCodexPath = if ($env:OS -eq 'Windows_NT') {
    $mockCodexWindowsPath
}
else {
    $mockCodexUnixPath
}
$workflowRelativePath = '.github/workflows/meandai-protocol-update.yml'
$failures = [System.Collections.Generic.List[string]]::new()
$tempRoots = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Invoke-TestGit {
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

function Invoke-Git {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    return Invoke-TestGit -Repository $Repository -Arguments $Arguments
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

    Invoke-TestGit -Repository $Repository -Arguments @('config', 'user.name', 'meAndAI Test') | Out-Null
    Invoke-TestGit -Repository $Repository -Arguments @('config', 'user.email', 'meandai-test@example.invalid') | Out-Null
    Invoke-TestGit -Repository $Repository -Arguments @('config', 'commit.gpgsign', 'false') | Out-Null
    Invoke-TestGit -Repository $Repository -Arguments @('config', 'core.autocrlf', 'false') | Out-Null
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
    $global:QuickAdoptionExistingSecrets = [System.Collections.Generic.List[string]]::new()
    $global:QuickAdoptionRepoName = ''
    $global:QuickAdoptionDefaultBranch = 'main'
    $global:QuickAdoptionOwner = 'test-owner'
    $global:QuickAdoptionNewRemote = ''
    $global:QuickAdoptionTargetPath = ''
    $global:QuickAdoptionDenyTargetAccess = $false
    $codexLogRoot = New-TempRoot -Name 'codex-log'
    $global:QuickAdoptionCodexLog = Join-Path $codexLogRoot 'calls.jsonl'
    New-Item -ItemType File -Path $global:QuickAdoptionCodexLog -Force | Out-Null
    $env:MEANDAI_TEST_CODEX_LOG = $global:QuickAdoptionCodexLog
    $env:MEANDAI_TEST_CODEX_MODE = 'Success'
    $env:MEANDAI_TEST_CODEX_TARGET = ''
    $env:MEANDAI_TEST_CODEX_REMOTE = ''
    $global:QuickAdoptionPrReadyCalls = 0
    $global:QuickAdoptionPrHead = ''
    $global:QuickAdoptionRemotePath = ''
    $global:QuickAdoptionRunListCalls = 0
    $global:QuickAdoptionPrListCalls = 0
    $global:QuickAdoptionProposalMode = 'ValidFull'
    $global:QuickAdoptionPrMetadataMode = 'Valid'
    $global:QuickAdoptionLabels = [System.Collections.Generic.List[string]]::new()
    $global:QuickAdoptionIssue = $null
    $global:QuickAdoptionIssueLabels = [System.Collections.Generic.List[string]]::new()
    $global:QuickAdoptionEvents = [System.Collections.Generic.List[string]]::new()
    $global:QuickAdoptionWorkflowBytes = [IO.File]::ReadAllBytes($workflowPath)
    $global:QuickAdoptionWorkflowSha = Get-GitBlobSha -Bytes $global:QuickAdoptionWorkflowBytes
    $protocolFixtureRoot = New-TempRoot -Name 'protocol-repository'
    $global:QuickAdoptionProtocolRepository = Join-Path $protocolFixtureRoot 'source'
    New-Item -ItemType Directory -Path $global:QuickAdoptionProtocolRepository -Force | Out-Null
    & git init -b main $global:QuickAdoptionProtocolRepository 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to initialize the mock protocol repository.'
    }
    Set-TestGitIdentity -Repository $global:QuickAdoptionProtocolRepository
    Set-Content -LiteralPath (Join-Path $global:QuickAdoptionProtocolRepository 'PROTOCOL.md') `
        -Value '# Mock protocol source' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $global:QuickAdoptionProtocolRepository 'VERSION') `
        -Value '0.7.3' -NoNewline
    Invoke-TestGit -Repository $global:QuickAdoptionProtocolRepository -Arguments @(
        'add', 'PROTOCOL.md', 'VERSION'
    ) | Out-Null
    Invoke-TestGit -Repository $global:QuickAdoptionProtocolRepository -Arguments @(
        'commit', '-m', 'Create mock protocol release'
    ) | Out-Null
    Invoke-TestGit -Repository $global:QuickAdoptionProtocolRepository -Arguments @(
        'tag', 'v0.7.3'
    ) | Out-Null
    $global:QuickAdoptionProtocolSha = (@(Invoke-TestGit `
        -Repository $global:QuickAdoptionProtocolRepository -Arguments @('rev-parse', 'HEAD')))[0]
}

function Get-MockCodexCalls {
    if (-not (Test-Path -LiteralPath $global:QuickAdoptionCodexLog -PathType Leaf)) {
        return @()
    }
    $calls = [System.Collections.Generic.List[object]]::new()
    foreach ($line in [IO.File]::ReadAllLines($global:QuickAdoptionCodexLog)) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $calls.Add(($line | ConvertFrom-Json))
        }
    }
    return @($calls)
}

function Publish-MockAdoptionBranch {
    $branch = 'automation/meandai-capabilities-v0.7.3'
    if ($global:QuickAdoptionPrHead) {
        $remoteLine = @((Invoke-TestGit -Repository $global:QuickAdoptionTargetPath -Arguments @(
            'ls-remote', '--heads', 'origin', "refs/heads/$branch"
        )) | Select-Object -First 1)
        if ($remoteLine.Count -eq 1) {
            $global:QuickAdoptionPrHead = ([string]$remoteLine[0]).Split("`t")[0]
        }
        return
    }

    $work = New-TempRoot -Name 'adoption-branch'
    $clone = Join-Path $work 'clone'
    & git clone $global:QuickAdoptionRemotePath $clone 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to clone the mock adoption remote.'
    }
    Set-TestGitIdentity -Repository $clone
    Invoke-TestGit -Repository $clone -Arguments @('checkout', '-b', $branch, 'origin/main') | Out-Null

    $manifestPath = Join-Path $clone '.ai/adoption/meandai-capabilities.json'
    New-Item -ItemType Directory -Path (Split-Path -Parent $manifestPath) -Force | Out-Null
    $manifestOnly = $global:QuickAdoptionProposalMode -ceq 'ManifestOnly'
    $proposalProtocolSha = if ($global:QuickAdoptionProposalMode -ceq 'WrongProtocolSha') {
        (@(Invoke-TestGit -Repository $clone -Arguments @('rev-parse', 'origin/main')))[0]
    }
    else {
        $global:QuickAdoptionProtocolSha
    }
    $manifest = [ordered]@{
        schema = 1
        operation = 'ai-capabilities-adoption'
        state = if ($manifestOnly) { 'AdoptionReviewRequired' } else { 'BootstrapReady' }
        repository = $global:QuickAdoptionRepoName
        targetTag = 'v0.7.3'
        protocolSha = $global:QuickAdoptionProtocolSha
        collisions = if ($manifestOnly) { @('AGENTS.md') } else { @() }
        proposedPaths = @('.ai/protocol', '.ai/adoption/meandai-capabilities.json')
        requiredTasks = @('Remove the manifest before readiness.')
    } | ConvertTo-Json -Depth 5
    Set-Content -LiteralPath $manifestPath -Value $manifest -Encoding UTF8
    if (-not $manifestOnly) {
        $gitmodules = @(
            '[submodule ".ai/protocol"]',
            "`tpath = .ai/protocol",
            "`turl = https://github.com/hasanmanzak/meAndAI.git",
            ''
        ) -join "`n"
        Set-Content -LiteralPath (Join-Path $clone '.gitmodules') -Value $gitmodules -NoNewline
        Invoke-TestGit -Repository $clone -Arguments @(
            'update-index', '--add', '--cacheinfo', "160000,$proposalProtocolSha,.ai/protocol"
        ) | Out-Null
        Invoke-TestGit -Repository $clone -Arguments @(
            'add', '--', '.gitmodules', '.ai/adoption/meandai-capabilities.json'
        ) | Out-Null
    }
    else {
        Invoke-TestGit -Repository $clone -Arguments @(
            'add', '--', '.ai/adoption/meandai-capabilities.json'
        ) | Out-Null
    }
    Invoke-TestGit -Repository $clone -Arguments @('commit', '-m', 'Create mock adoption draft') | Out-Null
    Invoke-TestGit -Repository $clone -Arguments @('push', 'origin', $branch) | Out-Null
    $global:QuickAdoptionPrHead = (@(Invoke-TestGit -Repository $clone -Arguments @('rev-parse', 'HEAD')))[0]
}

function Reset-MockAdoptionProposal {
    $branch = 'automation/meandai-capabilities-v0.7.3'
    Invoke-TestGit -Repository $global:QuickAdoptionTargetPath -Arguments @(
        'push', 'origin', '--delete', $branch
    ) | Out-Null
    $global:QuickAdoptionPrHead = ''
    $global:QuickAdoptionPrReadyCalls = 0
    $global:QuickAdoptionRunListCalls = 0
    $global:QuickAdoptionPrListCalls = 0
}

function global:Invoke-RestMethod {
    [CmdletBinding()]
    param(
        [string]$Uri,
        [hashtable]$Headers,
        [string]$Method = 'Get'
    )

    if ($Uri -match '/contents/templates/project/\.github/workflows/meandai-protocol-update\.yml\?ref=v0\.7\.3$') {
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

function global:Invoke-WebRequest {
    [CmdletBinding()]
    param(
        [string]$Uri,
        [hashtable]$Headers,
        [string]$OutFile,
        [switch]$UseBasicParsing
    )

    if ($Uri -notmatch '/repos/hasanmanzak/meAndAI/zipball/[0-9a-f]{40}$') {
        throw "Unexpected Invoke-WebRequest call: $Uri"
    }
    $archiveRoot = New-TempRoot -Name 'protocol-source'
    $sourceRoot = Join-Path $archiveRoot 'openai-mock-protocol'
    New-Item -ItemType Directory -Path $sourceRoot -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $sourceRoot 'PROTOCOL.md') -Value '# Mock protocol source' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $sourceRoot 'VERSION') -Value '0.7.3' -NoNewline
    Compress-Archive -LiteralPath $sourceRoot -DestinationPath $OutFile -Force
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
    $protocolSourceEndpoint = 'repos/hasanmanzak/meAndAI/contents/templates/project/.github/workflows/meandai-protocol-update.yml?ref=v0.7.3'
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'api' -and
        $Arguments -contains $protocolSourceEndpoint) {
        return (@{
            content = [Convert]::ToBase64String($global:QuickAdoptionWorkflowBytes)
            encoding = 'base64'
            sha = $global:QuickAdoptionWorkflowSha
        } | ConvertTo-Json -Compress)
    }
    if ($Arguments.Count -ge 4 -and $Arguments[0] -eq 'repo' -and
        $Arguments[1] -eq 'clone' -and $Arguments[2] -eq 'hasanmanzak/meAndAI') {
        & git clone $global:QuickAdoptionProtocolRepository $Arguments[3] 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to clone the mock protocol repository.'
        }
        return
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
        Invoke-TestGit -Repository $global:QuickAdoptionTargetPath -Arguments @(
            'config', "url.$($global:QuickAdoptionNewRemote.Replace('\\', '/')).insteadOf",
            "https://github.com/$($global:QuickAdoptionRepoName).git"
        ) | Out-Null
        Invoke-TestGit -Repository $global:QuickAdoptionTargetPath -Arguments @(
            'remote', 'add', 'origin', "https://github.com/$($global:QuickAdoptionRepoName).git"
        ) | Out-Null
        return
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'secret' -and $Arguments[1] -eq 'list') {
        $items = @($global:QuickAdoptionExistingSecrets | ForEach-Object {
            [ordered]@{ name = $_ }
        })
        return (ConvertTo-Json -InputObject $items -Compress)
    }
    if ($Arguments.Count -ge 3 -and $Arguments[0] -eq 'secret' -and $Arguments[1] -eq 'set') {
        $global:QuickAdoptionSecrets.Add([pscustomobject]@{
            Name = $Arguments[2]
            Value = $stdin
            Arguments = @($Arguments)
        })
        if ($global:QuickAdoptionExistingSecrets -notcontains $Arguments[2]) {
            $global:QuickAdoptionExistingSecrets.Add($Arguments[2])
        }
        return
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'label' -and $Arguments[1] -eq 'list') {
        return (@($global:QuickAdoptionLabels | ForEach-Object {
            [ordered]@{ name = $_ }
        }) | ConvertTo-Json -Compress)
    }
    if ($Arguments.Count -ge 3 -and $Arguments[0] -eq 'label' -and $Arguments[1] -eq 'create') {
        if ($global:QuickAdoptionLabels -notcontains $Arguments[2]) {
            $global:QuickAdoptionLabels.Add($Arguments[2])
        }
        return
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'issue' -and $Arguments[1] -eq 'list') {
        if ($null -eq $global:QuickAdoptionIssue) {
            return '[]'
        }
        return (@($global:QuickAdoptionIssue) | ConvertTo-Json -Compress)
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'issue' -and $Arguments[1] -eq 'create') {
        $bodyIndex = [Array]::IndexOf([object[]]$Arguments, '--body-file')
        if ($bodyIndex -lt 0 -or $bodyIndex + 1 -ge $Arguments.Count) {
            throw 'Mock adoption issue was not created through a body file.'
        }
        $global:QuickAdoptionIssue = [pscustomobject]@{
            number = 84
            url = "https://github.com/$($global:QuickAdoptionRepoName)/issues/84"
            title = 'Track meAndAI AI capabilities adoption from v0.7.3'
            body = [IO.File]::ReadAllText($Arguments[$bodyIndex + 1])
            state = 'OPEN'
        }
        for ($index = 0; $index -lt $Arguments.Count - 1; $index++) {
            if ($Arguments[$index] -ceq '--label') {
                $label = [string]$Arguments[$index + 1]
                if ($global:QuickAdoptionIssueLabels -notcontains $label) {
                    $global:QuickAdoptionIssueLabels.Add($label)
                }
                if ($label -ceq 'status:needs-review') {
                    $global:QuickAdoptionEvents.Add('issue-label:add:status:needs-review')
                }
            }
        }
        return $global:QuickAdoptionIssue.url
    }
    if ($Arguments.Count -ge 3 -and $Arguments[0] -eq 'issue' -and
        $Arguments[1] -in @('edit', 'reopen')) {
        if ($null -eq $global:QuickAdoptionIssue -or
            [string]$global:QuickAdoptionIssue.number -cne [string]$Arguments[2]) {
            throw 'Mock adoption issue identity mismatch.'
        }
        $global:QuickAdoptionIssue.state = 'OPEN'
        if ($Arguments[1] -ceq 'edit') {
            for ($index = 0; $index -lt $Arguments.Count - 1; $index++) {
                $operation = [string]$Arguments[$index]
                $label = [string]$Arguments[$index + 1]
                if ($operation -ceq '--add-label') {
                    if ($global:QuickAdoptionIssueLabels -notcontains $label) {
                        $global:QuickAdoptionIssueLabels.Add($label)
                    }
                    if ($label -ceq 'status:needs-review') {
                        $global:QuickAdoptionEvents.Add('issue-label:add:status:needs-review')
                    }
                }
                elseif ($operation -ceq '--remove-label') {
                    [void]$global:QuickAdoptionIssueLabels.Remove($label)
                }
            }
        }
        return
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'workflow' -and $Arguments[1] -eq 'run') {
        Publish-MockAdoptionBranch
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
        Publish-MockAdoptionBranch
        if ([string]$global:QuickAdoptionPrHead -notmatch '^[0-9a-f]{40}$') {
            throw "Mock adoption head is invalid: '$($global:QuickAdoptionPrHead)'"
        }
        $global:QuickAdoptionPrListCalls++
        if ($global:QuickAdoptionPrListCalls -gt 2) {
            throw 'Mock deterministic pull request was queried more than twice.'
        }
        $proposalState = if ($global:QuickAdoptionProposalMode -ceq 'ManifestOnly') {
            'AdoptionReviewRequired'
        }
        else {
            'BootstrapReady'
        }
        $marker = [ordered]@{
            schema = 2
            state = $proposalState
            target = 'v0.7.3'
            protocolSha = $global:QuickAdoptionProtocolSha
            head = $global:QuickAdoptionPrHead
            repository = $global:QuickAdoptionRepoName
            actor = $global:QuickAdoptionOwner
        } | ConvertTo-Json -Compress
        $pullRequest = [ordered]@{
            number = 42
            url = "https://github.com/$($global:QuickAdoptionRepoName)/pull/42"
            isDraft = ($global:QuickAdoptionPrReadyCalls -eq 0)
            state = 'OPEN'
            baseRefName = $global:QuickAdoptionDefaultBranch
            headRefName = 'automation/meandai-capabilities-v0.7.3'
            headRefOid = $global:QuickAdoptionPrHead
            headRepository = [ordered]@{ nameWithOwner = $global:QuickAdoptionRepoName }
            author = [ordered]@{ login = $global:QuickAdoptionOwner }
            body = "<!-- meandai-capabilities-adoption:$marker -->`n`nMock adoption proposal."
        }
        switch ($global:QuickAdoptionPrMetadataMode) {
            'WrongBase' { $pullRequest.baseRefName = 'develop' }
            'ForeignHead' {
                $pullRequest.headRepository = [ordered]@{ nameWithOwner = 'foreign-owner/consumer' }
            }
            'InvalidMarker' {
                $pullRequest.body = '<!-- meandai-capabilities-adoption:{"schema":1} -->'
            }
            'WrongAuthor' { $pullRequest.author = [ordered]@{ login = 'untrusted-actor' } }
            'NonDraft' { $pullRequest.isDraft = $false }
            'MarkerHeadMismatch' {
                $badMarker = [ordered]@{
                    schema = 2
                    state = $proposalState
                    target = 'v0.7.3'
                    protocolSha = $global:QuickAdoptionProtocolSha
                    head = ('0' * 40)
                    repository = $global:QuickAdoptionRepoName
                    actor = $global:QuickAdoptionOwner
                } | ConvertTo-Json -Compress
                $pullRequest.body = "<!-- meandai-capabilities-adoption:$badMarker -->"
            }
            'Valid' { }
            default { throw "Unknown mock pull-request metadata mode '$($global:QuickAdoptionPrMetadataMode)'." }
        }
        return (@($pullRequest) | ConvertTo-Json -Depth 5 -Compress)
    }
    if ($Arguments.Count -ge 2 -and $Arguments[0] -eq 'pr' -and $Arguments[1] -eq 'ready') {
        $global:QuickAdoptionEvents.Add('pr-ready')
        $global:QuickAdoptionPrReadyCalls++
        return
    }

    throw "Unexpected gh call: $joined"
}

try {
    foreach ($requiredPath in @(
        $launcherPath, $guidePath, $workflowPath, $mockCodexScriptPath,
        $mockCodexWindowsPath, $mockCodexUnixPath
    )) {
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
            'v0.7.3',
            'FG_PAT.txt',
            'MEANDAI_RO_FG_PAT.txt',
            'MEANDAI_UPDATER_TOKEN',
            'MEANDAI_PROTOCOL_TOKEN',
            'templates/project/.github/workflows/meandai-protocol-update.yml',
            '.github/workflows/meandai-protocol-update.yml',
            'Invoke-RestMethod',
            'Get-RepositorySecretNames',
            'gh secret list',
            'gh secret set',
            'already exists and was preserved',
            'info/exclude',
            '--private',
            'workflow run',
            'WorkflowTimeoutMinutes',
            'CodexTimeoutMinutes',
            'SkipLifecycleDispatch',
            'SkipLocalCodex',
            "Alias('SkipCodexDelegation')",
            'codex exec',
            '@openai/codex@',
            '0.144.4',
            'headRefOid',
            '--ephemeral',
            '--sandbox',
            'workspace-write',
            'sandbox_workspace_write.network_access=false',
            'WaitForExit',
            'Ensure-AdoptionLabels',
            'Ensure-AdoptionIssue',
            'Set-AdoptionIssueReadyForReview',
            'Get-ValidatedAdoptionManifest',
            'Get-ValidatedAdoptionChangeSet',
            'prior manifest removal has no launcher-owned validation evidence',
            '160000',
            '--force-with-lease'
        )) {
            if (-not $launcher.Contains($required)) {
                Add-Failure "TEST-0033 launcher is missing '$required'"
            }
        }
        if ($launcher -match '[''"]--body[''"]') {
            Add-Failure "TEST-0033 launcher contains forbidden secret body argument '--body'"
        }
        foreach ($forbidden in @(
            '@codex', 'Codex Cloud', 'gh pr merge', 'git add .',
            'sandbox_workspace_write.network_access=true'
        )) {
            if ($launcher.Contains($forbidden)) {
                Add-Failure "TEST-0033 launcher contains forbidden behavior '$forbidden'"
            }
        }
        $tokens = $null
        $parseErrors = $null
        $launcherAst = [System.Management.Automation.Language.Parser]::ParseInput(
            $launcher, [ref]$tokens, [ref]$parseErrors
        )
        $completionFunctions = @($launcherAst.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -ceq 'Complete-AdoptionWithLocalCodex'
        }, $true))
        if ($parseErrors.Count -ne 0 -or $completionFunctions.Count -ne 1 -or
            ($completionFunctions[0].Extent.EndLineNumber -
             $completionFunctions[0].Extent.StartLineNumber + 1) -gt 170) {
            Add-Failure 'TEST-0050 local adoption completion exceeds its bounded 170-line responsibility seam.'
        }
    }

    if (Test-Path -LiteralPath $guidePath -PathType Leaf) {
        $guide = Get-Content -LiteralPath $guidePath -Raw
        $normalizedGuide = [regex]::Replace($guide, '\s+', ' ')
        foreach ($required in @(
            'v0.7.3',
            'FG_PAT.txt',
            'MEANDAI_RO_FG_PAT.txt',
            'MEANDAI_UPDATER_TOKEN',
            'MEANDAI_PROTOCOL_TOKEN',
            'Invoke-MeAndAIQuickAdoption.ps1',
            '.ai/adoption/meandai-capabilities.json',
            'dispatches the lifecycle workflow',
            'local Codex CLI',
            'temporary clone',
            'headRefOid',
            '@openai/codex@0.144.4',
            'CodexTimeoutMinutes',
            'spawned-command network access disabled',
            'canonically marked adoption issue',
            'preserves either canonical name that already exists',
            'does not validate value, scope, expiry, or usability',
            'selected-repository',
            'Codex prompt',
            'Quick command'
        )) {
            if (-not $normalizedGuide.Contains($required)) {
                Add-Failure "TEST-0037 quick guide is missing '$required'"
            }
        }
        foreach ($requiredBoundary in @(
            'The displayed prompt is not the adoption entry point.',
            'original target directory',
            'never copied into the isolated clone',
            'parent launcher retains network access',
            'configured model service remains reachable',
            'before and after this Codex step'
        )) {
            if (-not $normalizedGuide.Contains($requiredBoundary)) {
                Add-Failure "TEST-0051 quick guide does not explain '$requiredBoundary'"
            }
        }
        foreach ($forbidden in @(
            'Codex Cloud', '@codex', 'sandbox_workspace_write.network_access=true'
        )) {
            if ($guide.Contains($forbidden)) {
                Add-Failure "TEST-0041 quick guide contains obsolete Cloud behavior '$forbidden'"
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
        $global:QuickAdoptionRemotePath = $existingRemote
        $env:MEANDAI_TEST_CODEX_TARGET = $existingRepo
        $env:MEANDAI_TEST_CODEX_REMOTE = $existingRemote

        $runOutput = @(& $launcherPath -TargetPath $existingRepo `
            -CodexCommand $mockCodexPath 2>&1) -join [Environment]::NewLine
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
        $codexCalls = @(Get-MockCodexCalls)
        $execCalls = @($codexCalls | Where-Object {
            $_.Arguments.Count -gt 0 -and $_.Arguments[0] -eq 'exec'
        })
        if ($dispatchCalls.Count -ne 1 -or $execCalls.Count -ne 1 -or
            -not $execCalls[0].Stdin.Contains('.ai/adoption/meandai-capabilities.json') -or
            -not $execCalls[0].Stdin.Contains('/issues/84') -or
            $execCalls[0].Stdin.Contains('Use gh') -or
            $global:QuickAdoptionPrReadyCalls -ne 1) {
            Add-Failure 'TEST-0039 default adoption did not complete once through local Codex and mark the draft ready.'
        }
        $reviewEvents = @($global:QuickAdoptionEvents | Where-Object {
            $_ -ceq 'issue-label:add:status:needs-review'
        })
        $readyEventIndex = $global:QuickAdoptionEvents.IndexOf('pr-ready')
        $reviewEventIndex = $global:QuickAdoptionEvents.IndexOf(
            'issue-label:add:status:needs-review'
        )
        if ($reviewEvents.Count -ne 1 -or $readyEventIndex -lt 0 -or
            $reviewEventIndex -le $readyEventIndex) {
            Add-Failure 'TEST-0049 adoption issue review status was not applied exactly once after pull-request readiness.'
        }
        $expectedLabels = @(
            'type:epic', 'type:feature', 'type:subfeature', 'type:task', 'type:bug',
            'type:finding', 'priority:p0', 'priority:p1', 'priority:p2', 'priority:p3',
            'status:blocked', 'status:in-progress', 'status:needs-review'
        )
        if ($global:QuickAdoptionLabels.Count -ne $expectedLabels.Count -or
            @($expectedLabels | Where-Object { $global:QuickAdoptionLabels -notcontains $_ }).Count -ne 0 -or
            $null -eq $global:QuickAdoptionIssue) {
            Add-Failure 'TEST-0039 launcher did not reconcile the deterministic Agile labels and adoption issue.'
        }
        $adoptionPaths = @(Invoke-Git -Repository $existingRemote -Arguments @(
            'ls-tree', '-r', '--name-only', 'refs/heads/automation/meandai-capabilities-v0.7.3'
        ))
        if ($adoptionPaths -contains '.ai/adoption/meandai-capabilities.json' -or
            $adoptionPaths -notcontains 'docs/ai-adoption.md') {
            Add-Failure 'TEST-0039 local Codex result was not published without the transient manifest.'
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
        $secretCountBeforeRerun = $global:QuickAdoptionSecrets.Count
        [void]$global:QuickAdoptionExistingSecrets.Remove('MEANDAI_UPDATER_TOKEN')
        $global:QuickAdoptionExistingSecrets.Add('meandai_updater_token')
        Remove-Item -LiteralPath (Join-Path $existingRepo 'FG_PAT.txt') -Force
        Remove-Item -LiteralPath (Join-Path $existingRepo 'MEANDAI_RO_FG_PAT.txt') -Force
        $headBeforeRerun = (Invoke-Git -Repository $existingRepo -Arguments @('rev-parse', 'HEAD'))[0]
        & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        $headAfterRerun = (Invoke-Git -Repository $existingRepo -Arguments @('rev-parse', 'HEAD'))[0]
        if ($headBeforeRerun -cne $headAfterRerun) {
            Add-Failure 'TEST-0036 exact rerun created a duplicate commit.'
        }
        $rerunCodexCalls = @(Get-MockCodexCalls)
        $rerunExecCalls = @($rerunCodexCalls | Where-Object {
            $_.Arguments.Count -gt 0 -and $_.Arguments[0] -eq 'exec'
        })
        $rerunLoginCalls = @($rerunCodexCalls | Where-Object {
            ($_.Arguments -join ' ') -eq 'login status'
        })
        if ($rerunExecCalls.Count -ne 1 -or $rerunLoginCalls.Count -ne 1 -or
            $global:QuickAdoptionPrReadyCalls -ne 1) {
            Add-Failure 'TEST-0041 exact rerun repeated local Codex discovery, execution, or pull-request readiness.'
        }
        if ($global:QuickAdoptionSecrets.Count -ne $secretCountBeforeRerun) {
            Add-Failure 'TEST-0045 exact rerun overwrote an existing mapped Actions secret.'
        }
        $protocolSourceEndpoint = 'repos/hasanmanzak/meAndAI/contents/templates/project/.github/workflows/meandai-protocol-update.yml?ref=v0.7.3'
        $protocolSourceCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -eq 'api' -and
            $_.Arguments -contains $protocolSourceEndpoint
        })
        if ($protocolSourceCalls.Count -ne 1) {
            Add-Failure 'TEST-0045 file-free rerun did not retrieve the exact protocol source through authenticated local gh.'
        }
        $secretListCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -eq 'secret' -and $_.Arguments[1] -eq 'list'
        })
        if ($secretListCalls.Count -lt 2) {
            Add-Failure 'TEST-0042 launcher did not inspect repository Actions secret names before reconciliation.'
        }
        foreach ($call in $secretListCalls) {
            $jsonIndex = [Array]::IndexOf([object[]]$call.Arguments, '--json')
            if ($jsonIndex -lt 0 -or $jsonIndex + 1 -ge $call.Arguments.Count -or
                $call.Arguments[$jsonIndex + 1] -cne 'name') {
                Add-Failure 'TEST-0042 launcher requested more than repository secret names during reconciliation.'
            }
        }

        Reset-MockAdoptionProposal
        $secretCountBeforeFileFreeAdoption = $global:QuickAdoptionSecrets.Count
        & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        $protocolCloneCalls = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 4 -and $_.Arguments[0] -eq 'repo' -and
            $_.Arguments[1] -eq 'clone' -and $_.Arguments[2] -eq 'hasanmanzak/meAndAI'
        })
        if ($protocolCloneCalls.Count -ne 1 -or $global:QuickAdoptionPrReadyCalls -ne 1 -or
            $global:QuickAdoptionSecrets.Count -ne $secretCountBeforeFileFreeAdoption) {
            Add-Failure 'TEST-0045 file-free semantic adoption did not use an exact authenticated local gh snapshot without rewriting secrets.'
        }

        $global:QuickAdoptionPrReadyCalls = 0
        $global:QuickAdoptionRunListCalls = 0
        $global:QuickAdoptionPrListCalls = 0
        [void]$global:QuickAdoptionExistingSecrets.Remove('MEANDAI_PROTOCOL_TOKEN')
        $secretCountBeforeMissingProtocolFile = $global:QuickAdoptionSecrets.Count
        $missingProtocolFileBlocked = $false
        try {
            & $launcherPath -TargetPath $existingRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $missingProtocolFileBlocked = $true
        }
        if (-not $missingProtocolFileBlocked -or
            $global:QuickAdoptionSecrets.Count -ne $secretCountBeforeMissingProtocolFile) {
            Add-Failure 'TEST-0045 a missing protocol secret did not require its mapped local credential file before mutation.'
        }

        Set-Content -LiteralPath (Join-Path $existingRepo 'MEANDAI_RO_FG_PAT.txt') `
            -Value 'read-token-value' -NoNewline
        $secretCountBeforePartialReconciliation = $global:QuickAdoptionSecrets.Count
        $codexCallsBeforeUnverifiedDraft = @(Get-MockCodexCalls)
        $codexCallCountBeforeUnverifiedDraft = $codexCallsBeforeUnverifiedDraft.Count
        & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        $codexCallsAfterUnverifiedDraft = @(Get-MockCodexCalls)
        $partialSecretWrites = @($global:QuickAdoptionSecrets |
            Select-Object -Skip $secretCountBeforePartialReconciliation)
        if ($partialSecretWrites.Count -ne 1 -or
            $partialSecretWrites[0].Name -cne 'MEANDAI_PROTOCOL_TOKEN') {
            Add-Failure 'TEST-0042 partial reconciliation did not create only the missing protocol secret.'
        }
        if ($global:QuickAdoptionPrReadyCalls -ne 0 -or
            $codexCallsAfterUnverifiedDraft.Count -ne $codexCallCountBeforeUnverifiedDraft) {
            Add-Failure "TEST-0040 an unverified manifest-free draft was promoted or reprocessed automatically (ready calls: $($global:QuickAdoptionPrReadyCalls); Codex calls: $codexCallCountBeforeUnverifiedDraft -> $($codexCallsAfterUnverifiedDraft.Count))."
        }

        foreach ($negativeMode in @('Unauthenticated', 'LeaveManifest', 'CreateCommit', 'RemoteRace')) {
            Reset-MockAdoptionProposal
            $env:MEANDAI_TEST_CODEX_MODE = $negativeMode
            $reviewEventCountBeforeNegative = @($global:QuickAdoptionEvents | Where-Object {
                $_ -ceq 'issue-label:add:status:needs-review'
            }).Count
            $blocked = $false
            try {
                & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
            }
            catch {
                $blocked = $true
            }
            if (-not $blocked -or $global:QuickAdoptionPrReadyCalls -ne 0) {
                Add-Failure "TEST-0040 local Codex negative mode '$negativeMode' did not block before readiness."
            }
            $reviewEventCountAfterNegative = @($global:QuickAdoptionEvents | Where-Object {
                $_ -ceq 'issue-label:add:status:needs-review'
            }).Count
            if ($reviewEventCountAfterNegative -ne $reviewEventCountBeforeNegative) {
                Add-Failure "TEST-0049 blocked local Codex mode '$negativeMode' assigned review-ready issue status."
            }
            $negativePaths = @(Invoke-TestGit -Repository $existingRemote -Arguments @(
                'ls-tree', '-r', '--name-only', 'refs/heads/automation/meandai-capabilities-v0.7.3'
            ))
            if ($negativePaths -contains 'docs/ai-adoption.md') {
                Add-Failure "TEST-0040 local Codex negative mode '$negativeMode' published the local completion."
            }
        }
        $env:MEANDAI_TEST_CODEX_MODE = 'Success'

        Reset-MockAdoptionProposal
        $global:QuickAdoptionProposalMode = 'ManifestOnly'
        $collisionCompleted = $true
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $collisionCompleted = $false
        }
        $collisionEntry = @((Invoke-Git -Repository $existingRemote -Arguments @(
            'ls-tree', 'refs/heads/automation/meandai-capabilities-v0.7.3', '--', '.ai/protocol'
        )))
        $collisionPaths = @(Invoke-Git -Repository $existingRemote -Arguments @(
            'ls-tree', '-r', '--name-only', 'refs/heads/automation/meandai-capabilities-v0.7.3'
        ))
        $expectedCollisionEntry = "160000 commit $($global:QuickAdoptionProtocolSha)`t.ai/protocol"
        if (-not $collisionCompleted -or $global:QuickAdoptionPrReadyCalls -ne 1 -or
            $collisionEntry.Count -ne 1 -or [string]$collisionEntry[0] -cne $expectedCollisionEntry -or
            $collisionPaths -contains '.ai/adoption/meandai-capabilities.json') {
            Add-Failure 'TEST-0046 token-backed manifest-only adoption did not publish the exact canonical protocol gitlink and remove the manifest.'
        }
        Reset-MockAdoptionProposal
        $global:QuickAdoptionProposalMode = 'ValidFull'

        foreach ($metadataMode in @(
            'WrongBase', 'ForeignHead', 'InvalidMarker', 'WrongAuthor', 'NonDraft',
            'MarkerHeadMismatch'
        )) {
            $global:QuickAdoptionPrMetadataMode = $metadataMode
            $codexCallCountBeforeInvalidMetadata = @(Get-MockCodexCalls).Count
            $metadataBlocked = $false
            try {
                & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
            }
            catch {
                $metadataBlocked = $true
            }
            $codexCallCountAfterInvalidMetadata = @(Get-MockCodexCalls).Count
            if (-not $metadataBlocked -or $global:QuickAdoptionPrReadyCalls -ne 0 -or
                $codexCallCountAfterInvalidMetadata -ne $codexCallCountBeforeInvalidMetadata) {
                Add-Failure "TEST-0047 pull-request metadata mode '$metadataMode' did not block before Codex execution and readiness."
            }
            Reset-MockAdoptionProposal
        }
        $global:QuickAdoptionPrMetadataMode = 'Valid'
        $global:QuickAdoptionProposalMode = 'WrongProtocolSha'
        $wrongPinBlocked = $false
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $wrongPinBlocked = $true
        }
        if (-not $wrongPinBlocked -or $global:QuickAdoptionPrReadyCalls -ne 0) {
            Add-Failure 'TEST-0047 a pre-existing protocol gitlink with the wrong SHA was promoted.'
        }
        Reset-MockAdoptionProposal
        $global:QuickAdoptionProposalMode = 'ValidFull'

        $secretCountBeforeDrift = $global:QuickAdoptionSecrets.Count
        Set-Content -LiteralPath (Join-Path $existingRepo $workflowRelativePath) -Value 'workflow-drift' -Encoding UTF8
        $driftBlocked = $false
        try {
            & $launcherPath -TargetPath $existingRepo -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $driftBlocked = $true
        }
        if (-not $driftBlocked -or $global:QuickAdoptionSecrets.Count -ne $secretCountBeforeDrift) {
            Add-Failure 'TEST-0036 workflow drift did not block before secret mutation.'
        }
        Invoke-Git -Repository $existingRepo -Arguments @('restore', $workflowRelativePath) | Out-Null

        Set-Content -LiteralPath (Join-Path $existingRepo 'FG_PAT.txt') -Value 'write-token-value' -NoNewline
        Invoke-Git -Repository $existingRepo -Arguments @('add', '-f', '--', 'FG_PAT.txt') | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('commit', '-m', 'Expose test credential path') | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('push', 'origin', 'main') | Out-Null
        $secretCountBeforeTracked = $global:QuickAdoptionSecrets.Count
        $trackedTokenBlocked = $false
        try {
            & $launcherPath -TargetPath $existingRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $trackedTokenBlocked = $true
        }
        if (-not $trackedTokenBlocked -or
            $global:QuickAdoptionSecrets.Count -ne $secretCountBeforeTracked) {
            Add-Failure 'TEST-0036 tracked token file did not block before secret mutation.'
        }

        Invoke-Git -Repository $existingRepo -Arguments @('rm', '--', 'FG_PAT.txt') | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @(
            'commit', '-m', 'Remove exposed test credential path'
        ) | Out-Null
        Invoke-Git -Repository $existingRepo -Arguments @('push', 'origin', 'main') | Out-Null
        $secretCountBeforeHistorical = $global:QuickAdoptionSecrets.Count
        $historicalTokenBlocked = $false
        try {
            & $launcherPath -TargetPath $existingRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $historicalTokenBlocked = $true
        }
        if (-not $historicalTokenBlocked -or
            $global:QuickAdoptionSecrets.Count -ne $secretCountBeforeHistorical) {
            Add-Failure 'TEST-0042 an absent optional token file in Git history did not block before secret mutation.'
        }

        Reset-Mocks
        $newRoot = New-TempRoot -Name 'new'
        $newRepo = Join-Path $newRoot 'new-consumer'
        $newRemote = Join-Path $newRoot 'new-consumer.git'
        New-Item -ItemType Directory -Path (Join-Path $newRepo 'src') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $newRepo 'src/app.txt') -Value 'local-only' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $newRepo 'MEANDAI_RO_FG_PAT.txt') -Value 'new-read-token' -NoNewline
        $global:QuickAdoptionRepoName = 'test-owner/new-consumer'
        $global:QuickAdoptionTargetPath = $newRepo
        $global:QuickAdoptionNewRemote = $newRemote
        $global:QuickAdoptionRemotePath = $newRemote

        $missingNewCredentialBlocked = $false
        try {
            & $launcherPath -TargetPath $newRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $missingNewCredentialBlocked = $true
        }
        $createCallsBeforeCredentials = @($global:QuickAdoptionGhCalls | Where-Object {
            $_.Arguments.Count -ge 2 -and $_.Arguments[0] -eq 'repo' -and
            $_.Arguments[1] -eq 'create'
        })
        if (-not $missingNewCredentialBlocked -or $createCallsBeforeCredentials.Count -ne 0 -or
            $global:QuickAdoptionSecrets.Count -ne 0) {
            Add-Failure 'TEST-0045 new-repository adoption did not require both local credential files before remote mutation.'
        }

        Set-Content -LiteralPath (Join-Path $newRepo 'FG_PAT.txt') -Value 'new-write-token' -NoNewline
        $global:QuickAdoptionDenyTargetAccess = $true
        $grantBlocked = $false
        try {
            & $launcherPath -TargetPath $newRepo -SkipLifecycleDispatch `
                -CodexCommand $mockCodexPath | Out-Null
        }
        catch {
            $grantBlocked = $true
        }
        if (-not $grantBlocked -or $global:QuickAdoptionSecrets.Count -ne 0) {
            Add-Failure 'TEST-0036 missing selected-repository grant did not block before secret storage.'
        }
        $global:QuickAdoptionDenyTargetAccess = $false
        & $launcherPath -TargetPath $newRepo -SkipLifecycleDispatch `
            -CodexCommand $mockCodexPath | Out-Null
        if ($global:QuickAdoptionSecrets.Count -ne 2 -or
            @($global:QuickAdoptionSecrets.Name) -notcontains 'MEANDAI_UPDATER_TOKEN' -or
            @($global:QuickAdoptionSecrets.Name) -notcontains 'MEANDAI_PROTOCOL_TOKEN') {
            Add-Failure 'TEST-0042 new-repository adoption did not create both missing Actions secrets.'
        }
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
    Add-Failure "Quick-adoption test harness failed: $($_.Exception.Message) [$($_.ScriptStackTrace)]"
}
finally {
    Remove-Item Function:\global:gh -ErrorAction SilentlyContinue
    Remove-Item Function:\global:Invoke-WebRequest -ErrorAction SilentlyContinue
    Remove-Item Function:\global:Invoke-RestMethod -ErrorAction SilentlyContinue
    foreach ($name in @(
        'MEANDAI_TEST_CODEX_LOG', 'MEANDAI_TEST_CODEX_MODE',
        'MEANDAI_TEST_CODEX_TARGET', 'MEANDAI_TEST_CODEX_REMOTE'
    )) {
        [Environment]::SetEnvironmentVariable($name, $null)
    }
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

Write-Host 'Quick-adoption tests passed: TEST-0033 through TEST-0042, TEST-0045 through TEST-0047, TEST-0049, and TEST-0051.' -ForegroundColor Green
