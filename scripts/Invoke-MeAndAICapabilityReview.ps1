[CmdletBinding()]
param(
    [string]$ConsumerRoot = (Get-Location).Path,
    [string]$ProtocolRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Repository = [string]$env:GITHUB_REPOSITORY,
    [string]$DefaultBranch = [string]$env:DEFAULT_BRANCH,
    [string]$DefaultHead = '',
    [string]$TargetVersion = '',
    [string]$IssueActorLogin = 'github-actions[bot]',
    [ValidateSet('PostFreshAdoption', 'AlreadyCurrent', 'PostProtocolUpdate')]
    [string]$DiscoveryContext = 'AlreadyCurrent',
    [string]$SourceVersion = '',
    [bool]$FrameworkInstalled = $true,
    [object[]]$Assessments = @(),
    [ValidateRange(1, 100)][int]$MaximumPages = 10,
    [ValidateRange(0, 2147483647)][int]$FinalizePullRequestNumber = 0,
    [System.Collections.IDictionary]$Runtime = @{},
    [AllowNull()]$FixtureInventory = $null,
    [switch]$PlanOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$script:LedgerRelativePath = '.ai/meandai-capabilities-state.json'
$script:ManifestRelativePath = '.ai/adoption/meandai-capability-review.json'
$script:MarkerPrefix = '<!-- meandai-capability-review:v1:'
$script:ClosurePrefix = '<!-- meandai-capability-review-closed:v1:'
$script:AttestationPrefix = '<!-- meandai-capability-review-attestation:v1:'
$script:ProtocolRepository = 'hasanmanzak/meAndAI'
$script:ProposalActor = $null
$script:IssueActor = $null
$script:RepositoryOwner = $null
$script:BaseLedgerDigest = ''

function Get-PropertyValue {
    param(
        [Parameter(Mandatory)]$Value,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Label,
        [switch]$AllowMissing
    )

    if ($null -eq $Value) {
        throw "$Label is null."
    }
    $property = $Value.PSObject.Properties[$Name]
    if ($null -eq $property) {
        if ($AllowMissing) {
            return $null
        }
        throw "$Label is missing '$Name'."
    }
    return ,$property.Value
}

function Assert-OrdinaryFile {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) {
        throw "$Label does not exist: $LiteralPath"
    }
    $attributes = [IO.File]::GetAttributes($LiteralPath)
    if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "$Label must not be a link or reparse point."
    }
}

function Assert-ContainedPath {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Label
    )

    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $pathFull = [IO.Path]::GetFullPath($Path)
    $prefix = $rootFull + [IO.Path]::DirectorySeparatorChar
    if (-not $pathFull.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label escapes the consumer checkout."
    }
    return $pathFull
}

function Assert-NoReparseBoundary {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        throw "$Label root does not exist."
    }
    $current = [IO.Path]::GetFullPath($Root)
    $segments = $RelativePath -split '[/\\]'
    foreach ($segment in @('') + $segments) {
        if (-not [string]::IsNullOrEmpty($segment)) {
            $current = Join-Path $current $segment
        }
        if (Test-Path -LiteralPath $current) {
            $attributes = [IO.File]::GetAttributes($current)
            if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "$Label crosses a link or reparse point."
            }
        }
    }
}

function Assert-GitSha {
    param([Parameter(Mandatory)][string]$Value, [string]$Label = 'Git SHA')

    if ($Value -cnotmatch '^[0-9a-f]{40}$') {
        throw "$Label must be one lowercase 40-character Git identity."
    }
}

function Get-Sha256Bytes {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return -join @($algorithm.ComputeHash($Bytes) | ForEach-Object {
            $_.ToString('x2', [Globalization.CultureInfo]::InvariantCulture)
        })
    }
    finally {
        $algorithm.Dispose()
    }
}

function Test-BytesEqual {
    param([AllowNull()][byte[]]$Left, [AllowNull()][byte[]]$Right)

    if ($null -eq $Left -or $null -eq $Right) {
        return $null -eq $Left -and $null -eq $Right
    }
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

function Invoke-NativeCapture {
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string[]]$Arguments,
        [int[]]$AllowedExitCodes = @(0)
    )

    $output = @(& $Command @Arguments 2>&1 | ForEach-Object { [string]$_ })
    $exitCode = $LASTEXITCODE
    if ($AllowedExitCodes -cnotcontains $exitCode) {
        $rendered = $output -join "`n"
        throw "$Command failed with exit code $exitCode. $rendered"
    }
    return [pscustomobject][ordered]@{
        ExitCode = $exitCode
        Output = $output
        Text = ($output -join "`n").Trim()
    }
}

function Invoke-ReviewGit {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [int[]]$AllowedExitCodes = @(0)
    )

    if ($Runtime.Contains('Git')) {
        return & ([scriptblock]$Runtime['Git']) $Arguments $AllowedExitCodes
    }
    return Invoke-NativeCapture -Command 'git' -Arguments $Arguments `
        -AllowedExitCodes $AllowedExitCodes
}

function ConvertFrom-StrictUtf8Bytes {
    param(
        [Parameter(Mandatory)][byte[]]$Bytes,
        [Parameter(Mandatory)][string]$Label
    )

    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and
        $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
        throw "$Label must be UTF-8 without a byte-order mark."
    }
    try {
        $text = [Text.UTF8Encoding]::new($false, $true).GetString($Bytes)
    }
    catch {
        throw "$Label is not strict UTF-8."
    }
    if ($text.Contains("`r")) {
        throw "$Label must use LF line endings."
    }
    return $text
}

function Get-ProtocolGitBlobBytes {
    param(
        [Parameter(Mandatory)][string]$CommitSha,
        [Parameter(Mandatory)][string]$RelativePath
    )

    Assert-GitSha -Value $CommitSha -Label 'Historical protocol commit'
    if ($RelativePath -cnotmatch '^[A-Za-z0-9._/-]+$' -or
        $RelativePath.StartsWith('/') -or $RelativePath.Contains('..')) {
        throw 'Historical protocol blob path is not canonical.'
    }
    if ($Runtime.Contains('ProtocolGitBlob')) {
        $injected = & ([scriptblock]$Runtime['ProtocolGitBlob']) `
            $CommitSha $RelativePath
        if ($null -eq $injected) {
            throw "Historical protocol blob '$RelativePath' is absent."
        }
        return ,([byte[]]$injected)
    }

    $objectName = "${CommitSha}:$RelativePath"
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.WorkingDirectory = $protocolFull
    $startInfo.Arguments = "cat-file blob $objectName"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $stream = [IO.MemoryStream]::new()
    try {
        if (-not $process.Start()) {
            throw 'Git did not start for historical protocol blob acquisition.'
        }
        $errorTask = $process.StandardError.ReadToEndAsync()
        $process.StandardOutput.BaseStream.CopyTo($stream)
        $process.WaitForExit()
        $errorText = $errorTask.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) {
            throw "Historical protocol blob '$RelativePath' could not be read. $errorText"
        }
        return ,([byte[]]$stream.ToArray())
    }
    finally {
        $stream.Dispose()
        $process.Dispose()
    }
}

function ConvertTo-RequestJson {
    param([Parameter(Mandatory)]$Value)

    return ($Value | ConvertTo-Json -Compress -Depth 30)
}

function Invoke-DefaultGitHub {
    param(
        [Parameter(Mandatory)][string]$Method,
        [Parameter(Mandatory)][string]$Endpoint,
        [AllowNull()]$Body,
        [ValidateSet('Proposal', 'Issue', 'Protocol')]
        [string]$Authority = 'Proposal',
        [switch]$AcceptNotFound
    )

    $arguments = [System.Collections.Generic.List[string]]::new()
    $arguments.Add('api')
    $arguments.Add('--method')
    $arguments.Add($Method)
    $arguments.Add('-H')
    $arguments.Add('Accept: application/vnd.github+json')
    $arguments.Add('-H')
    $arguments.Add('X-GitHub-Api-Version: 2022-11-28')
    $temporaryPath = $null
    $hadGhToken = Test-Path -LiteralPath Env:GH_TOKEN
    $previousGhToken = [string]$env:GH_TOKEN
    try {
        if ($Authority -cne 'Proposal') {
            $tokenName = if ($Authority -ceq 'Issue') {
                'ISSUE_TOKEN'
            }
            else {
                'PROTOCOL_TOKEN'
            }
            $token = [string][Environment]::GetEnvironmentVariable($tokenName)
            if ([string]::IsNullOrWhiteSpace($token)) {
                throw "$tokenName is required for $($Authority.ToLowerInvariant())-scoped GitHub operations."
            }
            $env:GH_TOKEN = $token
        }
        if ($null -ne $Body) {
            $temporaryPath = [IO.Path]::GetTempFileName()
            [IO.File]::WriteAllText(
                $temporaryPath,
                (ConvertTo-RequestJson -Value $Body) + "`n",
                [Text.UTF8Encoding]::new($false)
            )
            $arguments.Add('--input')
            $arguments.Add($temporaryPath)
        }
        $arguments.Add($Endpoint)
        $result = Invoke-NativeCapture -Command 'gh' -Arguments @($arguments) `
            -AllowedExitCodes @(0, 1)
        if ($result.ExitCode -ne 0) {
            if ($AcceptNotFound -and
                $result.Text -match '(?i)(HTTP[ /][0-9.]*[ ]*404|Not Found.*404|HTTP 404)') {
                return $null
            }
            throw "GitHub API $Method $Endpoint failed. $($result.Text)"
        }
        if ([string]::IsNullOrWhiteSpace($result.Text)) {
            return $null
        }
        try {
            return $result.Text | ConvertFrom-Json
        }
        catch {
            throw "GitHub API $Method $Endpoint returned invalid JSON."
        }
    }
    finally {
        if ($Authority -cne 'Proposal') {
            if ($hadGhToken) {
                $env:GH_TOKEN = $previousGhToken
            }
            else {
                Remove-Item -LiteralPath Env:GH_TOKEN -ErrorAction SilentlyContinue
            }
        }
        if ($null -ne $temporaryPath -and
            (Test-Path -LiteralPath $temporaryPath -PathType Leaf)) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

function Invoke-ReviewGitHub {
    param(
        [Parameter(Mandatory)][string]$Method,
        [Parameter(Mandatory)][string]$Endpoint,
        [AllowNull()]$Body = $null,
        [ValidateSet('Proposal', 'Issue', 'Protocol')]
        [string]$Authority = 'Proposal',
        [switch]$AcceptNotFound
    )

    if ($Runtime.Contains('GitHub')) {
        return & ([scriptblock]$Runtime['GitHub']) $Method $Endpoint $Body `
            ([bool]$AcceptNotFound) $Authority
    }
    return Invoke-DefaultGitHub -Method $Method -Endpoint $Endpoint `
        -Body $Body -Authority $Authority -AcceptNotFound:$AcceptNotFound
}

function Get-PagedGitHubCollection {
    param(
        [Parameter(Mandatory)][string]$Endpoint,
        [Parameter(Mandatory)][string]$Label,
        [ValidateSet('Proposal', 'Issue')][string]$Authority = 'Proposal'
    )

    $separator = if ($Endpoint.Contains('?')) { '&' } else { '?' }
    $items = [System.Collections.Generic.List[object]]::new()
    for ($page = 1; $page -le $MaximumPages; $page++) {
        $pageEndpoint = "$Endpoint${separator}per_page=100&page=$page"
        $response = Invoke-ReviewGitHub -Method GET -Endpoint $pageEndpoint `
            -Authority $Authority
        $pageItems = @($response)
        foreach ($item in $pageItems) {
            if ($null -ne $item) {
                $items.Add($item)
            }
        }
        if ($pageItems.Count -lt 100) {
            return @($items)
        }
    }
    throw "$Label exceeds the bounded $MaximumPages-page inventory limit."
}

function Get-ActorRecord {
    param(
        [Parameter(Mandatory)]$User,
        [Parameter(Mandatory)][string]$Label
    )

    $id = [long](Get-PropertyValue -Value $User -Name id -Label $Label)
    $login = [string](Get-PropertyValue -Value $User -Name login -Label $Label)
    if ($id -le 0 -or [string]::IsNullOrWhiteSpace($login)) {
        throw "$Label has invalid actor identity."
    }
    return [pscustomobject][ordered]@{
        Id = $id
        Login = $login
    }
}

function Test-IsProposalActor {
    param([Parameter(Mandatory)]$Actor)

    return [long]$Actor.Id -eq [long]$script:ProposalActor.Id -and
        [string]$Actor.Login -ceq [string]$script:ProposalActor.Login
}

function Test-IsIssueActor {
    param([Parameter(Mandatory)]$Actor)

    return [long]$Actor.Id -eq [long]$script:IssueActor.Id -and
        [string]$Actor.Login -ceq [string]$script:IssueActor.Login
}

function Test-SameActorIdentity {
    param(
        [Parameter(Mandatory)]$Left,
        [Parameter(Mandatory)]$Right
    )

    return [long]$Left.Id -eq [long]$Right.Id -and
        [string]$Left.Login -ieq [string]$Right.Login
}

function Get-CollaboratorPermission {
    param(
        [Parameter(Mandatory)][string]$Login,
        [Parameter(Mandatory)][long]$ExpectedId
    )

    $escaped = [Uri]::EscapeDataString($Login)
    $response = Invoke-ReviewGitHub -Method GET `
        -Endpoint "repos/$Repository/collaborators/$escaped/permission" `
        -AcceptNotFound
    if ($null -eq $response) {
        return 'none'
    }
    $permission = [string](Get-PropertyValue -Value $response `
        -Name permission -Label "Collaborator '$Login' permission")
    $user = Get-PropertyValue -Value $response -Name user `
        -Label "Collaborator '$Login' permission"
    $actual = Get-ActorRecord -User $user `
        -Label "Collaborator '$Login' permission user"
    if ([long]$actual.Id -ne $ExpectedId -or -not $actual.Login.Equals(
        $Login,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Collaborator '$Login' permission resolved another actor."
    }
    return $permission
}

function Get-GitHubFileAtRef {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Ref,
        [switch]$AllowMissing
    )

    Assert-GitSha -Value $Ref -Label "GitHub content ref for '$RelativePath'"
    $escapedRef = [Uri]::EscapeDataString($Ref)
    $response = Invoke-ReviewGitHub -Method GET `
        -Endpoint "repos/$Repository/contents/${RelativePath}?ref=$escapedRef" `
        -AcceptNotFound:$AllowMissing
    if ($null -eq $response) {
        if (-not $AllowMissing) {
            throw "Required GitHub content '$RelativePath' is missing at '$Ref'."
        }
        return [pscustomobject][ordered]@{
            Exists = $false
            Bytes = $null
            Blob = ''
        }
    }
    $type = [string](Get-PropertyValue -Value $response -Name type `
        -Label "GitHub content '$RelativePath'" -AllowMissing)
    if (-not [string]::IsNullOrEmpty($type) -and $type -cne 'file') {
        throw "GitHub content '$RelativePath' is not a file."
    }
    $encoding = [string](Get-PropertyValue -Value $response -Name encoding `
        -Label "GitHub content '$RelativePath'")
    $content = [string](Get-PropertyValue -Value $response -Name content `
        -Label "GitHub content '$RelativePath'")
    if ($encoding -cne 'base64') {
        throw "GitHub content '$RelativePath' is not base64."
    }
    try {
        $bytes = [Convert]::FromBase64String(($content -replace '\s', ''))
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and
            $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            throw 'BOM'
        }
        [void][Text.UTF8Encoding]::new($false, $true).GetString($bytes)
    }
    catch {
        throw "GitHub content '$RelativePath' is not strict BOM-free UTF-8/base64."
    }
    $blob = [string](Get-PropertyValue -Value $response -Name sha `
        -Label "GitHub content '$RelativePath'" -AllowMissing)
    if (-not [string]::IsNullOrEmpty($blob)) {
        Assert-GitSha -Value $blob -Label "GitHub content '$RelativePath' blob"
    }
    return [pscustomobject][ordered]@{
        Exists = $true
        Bytes = [byte[]]$bytes
        Blob = $blob
    }
}

function ConvertTo-GitRefEndpointPath {
    param([Parameter(Mandatory)][string]$RefName)

    $segments = $RefName.Split(
        [char[]]@('/'),
        [StringSplitOptions]::None
    )
    if ($segments.Count -eq 0 -or @($segments | Where-Object {
        [string]::IsNullOrEmpty([string]$_)
    }).Count -gt 0) {
        throw 'Git ref name contains an empty path segment.'
    }
    return (@($segments | ForEach-Object {
        [Uri]::EscapeDataString([string]$_)
    }) -join '/')
}

function Get-SingleBodyField {
    param(
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)][string]$Name
    )

    $tick = [regex]::Escape([string][char]96)
    $pattern = '(?m)^' + [regex]::Escape($Name) + ': ' + $tick +
        '([^' + $tick + "`r`n]+)" + $tick + '$'
    $matches = [regex]::Matches($Body, $pattern)
    if ($matches.Count -ne 1) {
        throw "Capability review body must contain exactly one '$Name' field."
    }
    return [string]$matches[0].Groups[1].Value
}

function Get-ReviewBinding {
    param(
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)][string]$Marker,
        [switch]$PullRequest
    )

    if ([regex]::Matches($Body, [regex]::Escape($Marker)).Count -ne 1) {
        throw 'Capability review body does not contain exactly one canonical marker.'
    }
    $binding = [pscustomobject][ordered]@{
        CatalogDigest = Get-SingleBodyField -Body $Body -Name 'Catalog digest'
        BatchDigest = Get-SingleBodyField -Body $Body -Name 'Batch digest'
        BaseBranch = Get-SingleBodyField -Body $Body -Name 'Base branch'
        BaseHead = Get-SingleBodyField -Body $Body -Name 'Base head'
        BaseLedgerDigest = Get-SingleBodyField -Body $Body `
            -Name 'Base ledger digest'
        Branch = Get-SingleBodyField -Body $Body -Name 'Review branch'
        HandoffHead = Get-SingleBodyField -Body $Body -Name 'Handoff head'
        LedgerPrefixCount = [int](Get-SingleBodyField -Body $Body `
            -Name 'Ledger prefix count')
        ProposalActorId = [long](Get-SingleBodyField -Body $Body `
            -Name 'Proposal actor ID')
        ProposalActorLogin = Get-SingleBodyField -Body $Body `
            -Name 'Proposal actor login'
        IssueActorId = [long](Get-SingleBodyField -Body $Body `
            -Name 'Issue actor ID')
        IssueActorLogin = Get-SingleBodyField -Body $Body `
            -Name 'Issue actor login'
        IssueNumber = 0
        CapabilityBatch = @()
    }
    if ($PullRequest) {
        $binding.IssueNumber = [int](Get-SingleBodyField -Body $Body `
            -Name 'Tracking issue')
    }
    Assert-GitSha -Value $binding.BaseHead -Label 'Review base head'
    if ($binding.CatalogDigest -cnotmatch '^[0-9a-f]{64}$' -or
        $binding.BatchDigest -cnotmatch '^[0-9a-f]{64}$' -or
        $binding.BaseLedgerDigest -cnotmatch '^(?:missing|[0-9a-f]{64})$' -or
        $binding.HandoffHead -cnotmatch '^(?:pending|[0-9a-f]{40})$' -or
        $binding.LedgerPrefixCount -lt 0 -or
        $binding.ProposalActorId -le 0 -or
        [string]::IsNullOrWhiteSpace($binding.ProposalActorLogin) -or
        $binding.ProposalActorLogin.Contains("`r") -or
        $binding.ProposalActorLogin.Contains("`n") -or
        $binding.IssueActorId -le 0 -or
        [string]::IsNullOrWhiteSpace($binding.IssueActorLogin) -or
        $binding.IssueActorLogin.Contains("`r") -or
        $binding.IssueActorLogin.Contains("`n")) {
        throw 'Capability review body contains a noncanonical binding.'
    }
    $capabilityMatches = [regex]::Matches(
        $Body,
        '(?m)^- ([a-z][a-z0-9]*(?:-[a-z0-9]+)*)@([0-9a-f]{40}) \((AdoptionRequired|ReviewRequired)\)$'
    )
    if ($capabilityMatches.Count -eq 0) {
        throw 'Capability review body has no canonical open capability batch.'
    }
    $batch = [System.Collections.Generic.List[object]]::new()
    foreach ($match in $capabilityMatches) {
        $batch.Add([pscustomobject][ordered]@{
            Slug = [string]$match.Groups[1].Value
            DefinitionBlob = [string]$match.Groups[2].Value
            Outcome = [string]$match.Groups[3].Value
        })
    }
    $binding.CapabilityBatch = @($batch)
    return $binding
}

function New-ReviewBody {
    param(
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)][int]$LedgerPrefixCount,
        [int]$IssueNumber = 0,
        [string]$HandoffHead = 'pending',
        [string]$BaseLedgerDigest = $script:BaseLedgerDigest,
        [long]$ProposalActorId = [long]$script:ProposalActor.Id,
        [string]$ProposalActorLogin = [string]$script:ProposalActor.Login,
        [long]$IssueActorId = [long]$script:IssueActor.Id,
        [string]$IssueActorLogin = [string]$script:IssueActor.Login
    )

    $tick = [string][char]96
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add([string]$Plan.Marker)
    $lines.Add('')
    $lines.Add('This is a review-only meAndAI semantic capability handoff.')
    $lines.Add('Automation owns only the transient manifest; semantic consumer changes require maintainer review.')
    $lines.Add('')
    $lines.Add("Catalog digest: $tick$($Plan.CatalogDigest)$tick")
    $lines.Add("Batch digest: $tick$($Plan.BatchDigest)$tick")
    $lines.Add("Base branch: $tick$($Plan.BaseBranch)$tick")
    $lines.Add("Base head: $tick$($Plan.BaseHead)$tick")
    $lines.Add("Base ledger digest: $tick$BaseLedgerDigest$tick")
    $lines.Add("Review branch: $tick$($Plan.Branch)$tick")
    $lines.Add("Handoff head: $tick$HandoffHead$tick")
    $lines.Add("Ledger prefix count: $tick$LedgerPrefixCount$tick")
    $lines.Add("Proposal actor ID: $tick$ProposalActorId$tick")
    $lines.Add("Proposal actor login: $tick$ProposalActorLogin$tick")
    $lines.Add("Issue actor ID: $tick$IssueActorId$tick")
    $lines.Add("Issue actor login: $tick$IssueActorLogin$tick")
    if ($IssueNumber -gt 0) {
        $lines.Add("Tracking issue: $tick$IssueNumber$tick")
        $lines.Add('')
        $lines.Add("Tracking issue: #$IssueNumber")
    }
    $lines.Add('')
    $lines.Add('Capability batch:')
    foreach ($capability in @($Plan.CapabilityBatch)) {
        $lines.Add(
            "- $([string]$capability.Slug)@$([string]$capability.DefinitionBlob) ($([string]$capability.Outcome))"
        )
    }
    return ($lines -join "`n") + "`n"
}

function Get-CapabilityBatchDigest {
    param([Parameter(Mandatory)][object[]]$Capabilities)

    $lines = @($Capabilities | ForEach-Object {
        "$([string]$_.Slug)@$([string]$_.DefinitionBlob)"
    })
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($lines -join "`n")
    return Get-Sha256Bytes -Bytes $bytes
}

function Assert-CanonicalReviewBody {
    param(
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)]$Binding,
        [Parameter(Mandatory)]$Catalog,
        [switch]$PullRequest
    )

    $prefixCount = [int]$Binding.LedgerPrefixCount
    $catalogCapabilities = @($Catalog.Capabilities)
    if ($prefixCount -lt 0 -or $prefixCount -ge $catalogCapabilities.Count) {
        throw 'Capability review binding has an invalid catalog-prefix count.'
    }
    $expectedBatch = @($catalogCapabilities | Select-Object -Skip $prefixCount)
    $actualBatch = @($Binding.CapabilityBatch)
    if ($actualBatch.Count -ne $expectedBatch.Count) {
        throw 'Capability review body batch does not match the catalog suffix.'
    }
    for ($index = 0; $index -lt $expectedBatch.Count; $index++) {
        if ([string]$actualBatch[$index].Slug -cne
                [string]$expectedBatch[$index].Slug -or
            [string]$actualBatch[$index].DefinitionBlob -cne
                [string]$expectedBatch[$index].DefinitionBlob -or
            @('AdoptionRequired', 'ReviewRequired') -cnotcontains
                [string]$actualBatch[$index].Outcome) {
            throw 'Capability review body batch changed immutable capability identity.'
        }
    }
    $expectedDigest = Get-CapabilityBatchDigest -Capabilities $expectedBatch
    if ([string]$Binding.BatchDigest -cne $expectedDigest -or
        [string]$Binding.CatalogDigest -cne [string]$Catalog.CatalogDigest) {
        throw 'Capability review body digest does not match the release catalog.'
    }
    $pseudoPlan = [pscustomobject][ordered]@{
        Marker = Get-MeAndAICapabilityReviewMarker -Repository $Repository `
            -CatalogDigest $Catalog.CatalogDigest
        Repository = $Repository
        CatalogDigest = [string]$Binding.CatalogDigest
        BatchDigest = [string]$Binding.BatchDigest
        BaseBranch = [string]$Binding.BaseBranch
        BaseHead = [string]$Binding.BaseHead
        Branch = [string]$Binding.Branch
        CapabilityBatch = $actualBatch
    }
    $expectedBody = New-ReviewBody -Plan $pseudoPlan `
        -LedgerPrefixCount $prefixCount `
        -IssueNumber $(if ($PullRequest) {
            [int]$Binding.IssueNumber
        } else {
            0
        }) `
        -HandoffHead ([string]$Binding.HandoffHead) `
        -BaseLedgerDigest ([string]$Binding.BaseLedgerDigest) `
        -ProposalActorId ([long]$Binding.ProposalActorId) `
        -ProposalActorLogin ([string]$Binding.ProposalActorLogin) `
        -IssueActorId ([long]$Binding.IssueActorId) `
        -IssueActorLogin ([string]$Binding.IssueActorLogin)
    if ($Body -cne $expectedBody) {
        throw 'Capability review body is not the exact canonical handoff content.'
    }
}

function Assert-BindingMatchesPlan {
    param(
        [AllowNull()]$Binding,
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)][int]$LedgerPrefixCount,
        [string]$Label = 'Capability review binding'
    )

    if ($null -eq $Binding) {
        return
    }
    if ([string]$Binding.CatalogDigest -cne [string]$Plan.CatalogDigest -or
        [string]$Binding.BatchDigest -cne [string]$Plan.BatchDigest -or
        [string]$Binding.BaseBranch -cne [string]$Plan.BaseBranch -or
        [string]$Binding.BaseHead -cne [string]$Plan.BaseHead -or
        [string]$Binding.BaseLedgerDigest -cne $script:BaseLedgerDigest -or
        [string]$Binding.Branch -cne [string]$Plan.Branch -or
        [int]$Binding.LedgerPrefixCount -ne $LedgerPrefixCount -or
        [long]$Binding.ProposalActorId -ne [long]$script:ProposalActor.Id -or
        [string]$Binding.ProposalActorLogin -cne
            [string]$script:ProposalActor.Login -or
        [long]$Binding.IssueActorId -ne [long]$script:IssueActor.Id -or
        [string]$Binding.IssueActorLogin -cne [string]$script:IssueActor.Login) {
        throw "$Label drifted from the exact repository/catalog review plan."
    }
    if ($null -ne $Binding.PSObject.Properties['CapabilityBatch']) {
        $boundBatch = @($Binding.CapabilityBatch)
        $planBatch = @($Plan.CapabilityBatch)
        if ($boundBatch.Count -ne $planBatch.Count) {
            throw "$Label capability batch drifted from the review plan."
        }
        for ($index = 0; $index -lt $boundBatch.Count; $index++) {
            if ([string]$boundBatch[$index].Slug -cne
                    [string]$planBatch[$index].Slug -or
                [string]$boundBatch[$index].DefinitionBlob -cne
                    [string]$planBatch[$index].DefinitionBlob -or
                [string]$boundBatch[$index].Outcome -cne
                    [string]$planBatch[$index].Outcome) {
                throw "$Label capability batch drifted from the review plan."
            }
        }
    }
}

function ConvertFrom-ManifestContent {
    param(
        [Parameter(Mandatory)]$ContentResponse,
        [Parameter(Mandatory)][string]$Marker
    )

    $encoding = [string](Get-PropertyValue -Value $ContentResponse `
        -Name 'encoding' -Label 'Capability review manifest content')
    $content = [string](Get-PropertyValue -Value $ContentResponse `
        -Name 'content' -Label 'Capability review manifest content')
    if ($encoding -cne 'base64') {
        throw 'Capability review manifest content is not base64.'
    }
    try {
        $bytes = [Convert]::FromBase64String(($content -replace '\s', ''))
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and
            $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            throw 'BOM'
        }
        $text = [Text.UTF8Encoding]::new($false, $true).GetString($bytes)
    }
    catch {
        throw 'Capability review manifest is not strict BOM-free UTF-8/base64.'
    }
    if ($text.Contains("`r") -or -not $text.EndsWith("`n")) {
        throw 'Capability review manifest must use canonical LF text.'
    }
    try {
        $manifest = $text | ConvertFrom-Json
    }
    catch {
        throw 'Capability review manifest is not valid JSON.'
    }
    $expected = @(
        'schema', 'marker', 'catalogDigest', 'batchDigest', 'repository',
        'baseBranch', 'baseHead', 'baseLedgerDigest', 'branch', 'issueNumber',
        'ledgerPrefixCount', 'proposalActorId', 'proposalActorLogin',
        'issueActorId', 'issueActorLogin', 'capabilities'
    )
    $actual = @($manifest.PSObject.Properties | ForEach-Object { [string]$_.Name })
    if ($actual.Count -ne $expected.Count) {
        throw 'Capability review manifest has an unsupported property set.'
    }
    foreach ($name in $expected) {
        if ($actual -cnotcontains $name) {
            throw "Capability review manifest is missing '$name'."
        }
    }
    if (($manifest.schema -isnot [int] -and $manifest.schema -isnot [long]) -or
        [long]$manifest.schema -ne 1 -or
        [string]$manifest.marker -cne $Marker -or
        $manifest.capabilities -isnot [Array]) {
        throw 'Capability review manifest schema or marker is invalid.'
    }
    return [pscustomobject][ordered]@{
        Marker = [string]$manifest.marker
        CatalogDigest = [string]$manifest.catalogDigest
        BatchDigest = [string]$manifest.batchDigest
        Repository = [string]$manifest.repository
        BaseBranch = [string]$manifest.baseBranch
        BaseHead = [string]$manifest.baseHead
        BaseLedgerDigest = [string]$manifest.baseLedgerDigest
        Branch = [string]$manifest.branch
        IssueNumber = [long]$manifest.issueNumber
        LedgerPrefixCount = [int]$manifest.ledgerPrefixCount
        ProposalActorId = [long]$manifest.proposalActorId
        ProposalActorLogin = [string]$manifest.proposalActorLogin
        IssueActorId = [long]$manifest.issueActorId
        IssueActorLogin = [string]$manifest.issueActorLogin
        Capabilities = @($manifest.capabilities)
        Bytes = [byte[]]$bytes
    }
}

function New-ManifestBytes {
    param(
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)][long]$IssueNumber,
        [Parameter(Mandatory)][int]$LedgerPrefixCount,
        [string]$BaseLedgerDigest = $script:BaseLedgerDigest,
        [long]$ProposalActorId = [long]$script:ProposalActor.Id,
        [string]$ProposalActorLogin = [string]$script:ProposalActor.Login,
        [long]$IssueActorId = [long]$script:IssueActor.Id,
        [string]$IssueActorLogin = [string]$script:IssueActor.Login
    )

    $capabilities = @($Plan.CapabilityBatch | ForEach-Object {
        [ordered]@{
            slug = [string]$_.Slug
            definitionBlob = [string]$_.DefinitionBlob
            type = [string]$_.Type
            outcome = [string]$_.Outcome
        }
    })
    $manifest = [ordered]@{
        schema = 1
        marker = [string]$Plan.Marker
        catalogDigest = [string]$Plan.CatalogDigest
        batchDigest = [string]$Plan.BatchDigest
        repository = [string]$Plan.Repository
        baseBranch = [string]$Plan.BaseBranch
        baseHead = [string]$Plan.BaseHead
        baseLedgerDigest = $BaseLedgerDigest
        branch = [string]$Plan.Branch
        issueNumber = $IssueNumber
        ledgerPrefixCount = $LedgerPrefixCount
        proposalActorId = $ProposalActorId
        proposalActorLogin = $ProposalActorLogin
        issueActorId = $IssueActorId
        issueActorLogin = $IssueActorLogin
        capabilities = $capabilities
    }
    $text = (ConvertTo-RequestJson -Value $manifest) + "`n"
    return ,([Text.UTF8Encoding]::new($false).GetBytes($text))
}

function Assert-CanonicalManifest {
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)]$Catalog,
        [Parameter(Mandatory)][int]$LedgerPrefixCount
    )

    if ([string]$Manifest.Marker -cne [string]$Plan.Marker -or
        [string]$Manifest.CatalogDigest -cne [string]$Plan.CatalogDigest -or
        [string]$Manifest.BatchDigest -cne [string]$Plan.BatchDigest -or
        [string]$Manifest.Repository -cne [string]$Plan.Repository -or
        [string]$Manifest.BaseBranch -cne [string]$Plan.BaseBranch -or
        [string]$Manifest.BaseHead -cne [string]$Plan.BaseHead -or
        [string]$Manifest.BaseLedgerDigest -cne $script:BaseLedgerDigest -or
        [string]$Manifest.Branch -cne [string]$Plan.Branch -or
        [int]$Manifest.LedgerPrefixCount -ne $LedgerPrefixCount -or
        [long]$Manifest.ProposalActorId -ne [long]$script:ProposalActor.Id -or
        [string]$Manifest.ProposalActorLogin -cne
            [string]$script:ProposalActor.Login -or
        [long]$Manifest.IssueActorId -ne [long]$script:IssueActor.Id -or
        [string]$Manifest.IssueActorLogin -cne [string]$script:IssueActor.Login) {
        throw 'Capability review manifest drifted from the exact plan.'
    }
    $expectedBatch = @($Catalog.Capabilities | Select-Object `
        -Skip $LedgerPrefixCount)
    $actualBatch = @($Manifest.Capabilities)
    if ($actualBatch.Count -ne $expectedBatch.Count) {
        throw 'Capability review manifest batch does not match the catalog suffix.'
    }
    for ($index = 0; $index -lt $expectedBatch.Count; $index++) {
        if ([string]$actualBatch[$index].slug -cne
                [string]$expectedBatch[$index].Slug -or
            [string]$actualBatch[$index].definitionBlob -cne
                [string]$expectedBatch[$index].DefinitionBlob -or
            [string]$actualBatch[$index].type -cne
                [string]$expectedBatch[$index].Type -or
            [string]$actualBatch[$index].outcome -cne
                [string]$Plan.CapabilityBatch[$index].Outcome) {
            throw 'Capability review manifest changed immutable batch content.'
        }
    }
    $expectedBytes = New-ManifestBytes -Plan $Plan `
        -IssueNumber ([long]$Manifest.IssueNumber) `
        -LedgerPrefixCount $LedgerPrefixCount `
        -BaseLedgerDigest ([string]$Manifest.BaseLedgerDigest) `
        -ProposalActorId ([long]$Manifest.ProposalActorId) `
        -ProposalActorLogin ([string]$Manifest.ProposalActorLogin) `
        -IssueActorId ([long]$Manifest.IssueActorId) `
        -IssueActorLogin ([string]$Manifest.IssueActorLogin)
    if (-not (Test-BytesEqual -Left ([byte[]]$Manifest.Bytes) `
        -Right $expectedBytes)) {
        throw 'Capability review manifest is not exact canonical JSON.'
    }
}

function New-CanonicalClosureCommentBody {
    param([Parameter(Mandatory)][string]$Marker)

    return "$Marker`n`nVerified merged review, terminal ledger, default-branch containment, and exact-head branch cleanup.`n"
}

function New-CanonicalOwnerAttestationCommentBody {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][long]$PullRequestNumber,
        [Parameter(Mandatory)][string]$HeadSha
    )

    if ($Repository -cnotmatch '^[a-z0-9](?:[a-z0-9-]{0,38})/[a-z0-9._-]+$' -or
        $PullRequestNumber -le 0) {
        throw 'Owner attestation identity is not canonical.'
    }
    Assert-GitSha -Value $HeadSha -Label 'Owner attestation review head'
    $marker = $script:AttestationPrefix + $Repository + ':pr-' +
        $PullRequestNumber + ':head-' + $HeadSha + ' -->'
    return $marker + ' I reviewed the semantic capability changes at this exact pull-request head and attest that they are ready for finalization.'
}

function Get-ExactHeadOwnerAttestation {
    param(
        [Parameter(Mandatory)]$PullRequest
    )

    if ($null -eq $script:RepositoryOwner -or
        [string]$script:RepositoryOwner.Type -cne 'User' -or
        -not (Test-SameActorIdentity -Left $script:RepositoryOwner `
            -Right $PullRequest.Creator)) {
        return $null
    }

    $expectedBody = New-CanonicalOwnerAttestationCommentBody `
        -Repository $Repository `
        -PullRequestNumber ([long]$PullRequest.Number) `
        -HeadSha ([string]$PullRequest.HeadSha)
    $expectedMarker = $expectedBody.Substring(
        0,
        $expectedBody.IndexOf(' -->', [StringComparison]::Ordinal) + 4
    )
    $comments = @(Get-PagedGitHubCollection `
        -Endpoint "repos/$Repository/issues/$($PullRequest.Number)/comments" `
        -Label 'Capability review owner attestations' -Authority Issue)
    $matches = [System.Collections.Generic.List[object]]::new()
    foreach ($comment in $comments) {
        $body = [string](Get-PropertyValue -Value $comment -Name body `
            -Label 'Capability review owner attestation' -AllowMissing)
        $user = Get-PropertyValue -Value $comment -Name user `
            -Label 'Capability review owner attestation' -AllowMissing
        if ($null -eq $user) {
            continue
        }
        $actor = Get-ActorRecord -User $user `
            -Label 'Capability review owner attestation actor'
        if (-not (Test-SameActorIdentity -Left $actor `
            -Right $script:RepositoryOwner)) {
            continue
        }
        if ($body -ceq $expectedBody) {
            $matches.Add([pscustomobject][ordered]@{
                Actor = $actor
                Body = $body
            })
        }
        elseif ($body.Contains($expectedMarker)) {
            throw 'Trusted capability review owner attestation is not exact canonical evidence.'
        }
    }
    if ($matches.Count -gt 1) {
        throw 'Capability review contains duplicate or conflicting owner attestations.'
    }
    if ($matches.Count -ne 1) {
        return $null
    }

    $permission = Get-CollaboratorPermission `
        -Login ([string]$matches[0].Actor.Login) `
        -ExpectedId ([long]$matches[0].Actor.Id)
    if ($permission -cne 'admin') {
        return $null
    }
    return [pscustomobject][ordered]@{
        Id = [long]$matches[0].Actor.Id
        Login = [string]$matches[0].Actor.Login
        Permission = $permission
        Commit = [string]$PullRequest.HeadSha
    }
}

function Get-ClosureMarkerFromComments {
    param(
        [Parameter(Mandatory)][long]$IssueNumber,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$CatalogDigest
    )

    $comments = @(Get-PagedGitHubCollection `
        -Endpoint "repos/$Repository/issues/$IssueNumber/comments" `
        -Label 'Capability review issue comments' -Authority Issue)
    $prefix = [regex]::Escape(
        "$($script:ClosurePrefix)$Repository`:$CatalogDigest`:"
    )
    $matches = [System.Collections.Generic.List[string]]::new()
    foreach ($comment in $comments) {
        $body = [string](Get-PropertyValue -Value $comment -Name body `
            -Label 'Capability review issue comment' -AllowMissing)
        $user = Get-PropertyValue -Value $comment -Name user `
            -Label 'Capability review issue comment' -AllowMissing
        if ($null -eq $user) {
            continue
        }
        $actor = Get-ActorRecord -User $user `
            -Label 'Capability review issue comment actor'
        if (-not (Test-IsIssueActor -Actor $actor)) {
            continue
        }
        foreach ($match in [regex]::Matches(
            $body,
            $prefix + 'pr-[1-9][0-9]*:merge-[0-9a-f]{40} -->'
        )) {
            $marker = [string]$match.Value
            if ($body -cne (New-CanonicalClosureCommentBody -Marker $marker)) {
                throw 'Trusted capability review closure comment is not exact canonical evidence.'
            }
            $matches.Add($marker)
        }
    }
    $unique = @($matches | Sort-Object -Unique -CaseSensitive)
    if ($unique.Count -gt 1 -or $matches.Count -gt 1) {
        throw 'Capability review issue contains duplicate or conflicting closure evidence.'
    }
    if ($unique.Count -eq 1) {
        return [string]$unique[0]
    }
    return ''
}

function Get-ProductionInventory {
    param(
        [Parameter(Mandatory)]$Catalog,
        [Parameter(Mandatory)][string]$Marker,
        [Parameter(Mandatory)][string]$ExpectedBranch,
        [Parameter(Mandatory)][string]$CurrentDefaultHead,
        [switch]$SkipStaleCatalogGuard
    )

    $issuesRaw = @(Get-PagedGitHubCollection `
        -Endpoint "repos/$Repository/issues?state=all" `
        -Label 'Capability review issues' -Authority Issue)
    $issueCandidates = [System.Collections.Generic.List[object]]::new()
    $historicalIssueCandidates = [System.Collections.Generic.List[object]]::new()
    foreach ($raw in $issuesRaw) {
        if ($null -ne (Get-PropertyValue -Value $raw -Name pull_request `
            -Label 'Issue inventory item' -AllowMissing)) {
            continue
        }
        $body = [string](Get-PropertyValue -Value $raw -Name body `
            -Label 'Issue inventory item' -AllowMissing)
        $state = [string](Get-PropertyValue -Value $raw -Name state `
            -Label 'Issue inventory item')
        $user = Get-PropertyValue -Value $raw -Name user `
            -Label 'Issue inventory item' -AllowMissing
        if ($null -eq $user) {
            continue
        }
        $creator = Get-ActorRecord -User $user `
            -Label 'Capability review issue creator'
        if (-not (Test-IsIssueActor -Actor $creator)) {
            continue
        }
        $repoPrefix = "$($script:MarkerPrefix)$Repository`:"
        if ($state -ceq 'open' -and $body.Contains($repoPrefix) -and
            -not $body.Contains($Marker)) {
            if ($SkipStaleCatalogGuard) {
                continue
            }
            $markerMatches = [regex]::Matches(
                $body,
                [regex]::Escape($repoPrefix) +
                    '(?<digest>[0-9a-f]{64}) -->'
            )
            if ($markerMatches.Count -ne 1 -or
                [regex]::Matches(
                    $body,
                    [regex]::Escape($repoPrefix)
                ).Count -ne 1) {
                throw 'Historical capability-review issue lacks one canonical binding marker.'
            }
            $historicalMarker = [string]$markerMatches[0].Value
            try {
                $historicalBinding = Get-ReviewBinding -Body $body `
                    -Marker $historicalMarker
            }
            catch {
                throw "Historical capability-review issue lacks a canonical binding. $($_.Exception.Message)"
            }
            if ([string]$historicalBinding.HandoffHead -cne 'pending' -or
                [long]$historicalBinding.IssueActorId -ne [long]$creator.Id -or
                [string]$historicalBinding.IssueActorLogin -cne
                    [string]$creator.Login -or
                [long]$historicalBinding.ProposalActorId -ne
                    [long]$script:ProposalActor.Id -or
                [string]$historicalBinding.ProposalActorLogin -cne
                    [string]$script:ProposalActor.Login) {
                throw 'Historical capability-review issue has a noncanonical dual-authority binding.'
            }
            $historicalIssueCandidates.Add([pscustomobject][ordered]@{
                Number = [long](Get-PropertyValue -Value $raw -Name number `
                    -Label 'Historical capability review issue')
                State = 'Open'
                Marker = $historicalMarker
                CatalogDigest = [string]$markerMatches[0].Groups['digest'].Value
                Binding = $historicalBinding
                Body = $body
                Creator = $creator
            })
            continue
        }
        if (-not $body.Contains($Marker)) {
            continue
        }
        $binding = Get-ReviewBinding -Body $body -Marker $Marker
        if ([string]$binding.HandoffHead -cne 'pending') {
            throw 'Capability review issue must preserve a pending handoff head.'
        }
        if ([long]$binding.IssueActorId -ne [long]$creator.Id -or
            [string]$binding.IssueActorLogin -cne [string]$creator.Login -or
            [long]$binding.ProposalActorId -ne [long]$script:ProposalActor.Id -or
            [string]$binding.ProposalActorLogin -cne
                [string]$script:ProposalActor.Login) {
            throw 'Capability review issue actor bindings do not match its dual authorities.'
        }
        Assert-CanonicalReviewBody -Body $body -Binding $binding `
            -Catalog $Catalog
        $number = [long](Get-PropertyValue -Value $raw -Name number `
            -Label 'Capability review issue')
        $closure = Get-ClosureMarkerFromComments -IssueNumber $number `
            -Repository $Repository -CatalogDigest $Catalog.CatalogDigest
        $issueCandidates.Add([pscustomobject][ordered]@{
            Number = $number
            State = if ($state -ceq 'open') { 'Open' } else { 'Closed' }
            Marker = $Marker
            ClosureMarker = $closure
            Binding = $binding
            Body = $body
            Creator = $creator
        })
    }
    if ($issueCandidates.Count -gt 1) {
        throw 'Canonical inventory contains a duplicate issue.'
    }
    if ($historicalIssueCandidates.Count -gt 1) {
        throw 'Canonical historical inventory contains a duplicate issue.'
    }

    $escapedBranch = ConvertTo-GitRefEndpointPath -RefName $ExpectedBranch
    $branchRaw = Invoke-ReviewGitHub -Method GET `
        -Endpoint "repos/$Repository/git/ref/heads/$escapedBranch" `
        -AcceptNotFound
    $branchCandidates = @()
    if ($null -ne $branchRaw) {
        $object = Get-PropertyValue -Value $branchRaw -Name object `
            -Label 'Capability review branch'
        $headSha = [string](Get-PropertyValue -Value $object -Name sha `
            -Label 'Capability review branch')
        Assert-GitSha -Value $headSha -Label 'Capability review branch head'
        $branchCandidates = @([pscustomobject][ordered]@{
            Name = $ExpectedBranch
            BaseHead = ''
            HeadSha = $headSha
            Marker = $Marker
        })
    }

    $pullsRaw = @(Get-PagedGitHubCollection `
        -Endpoint "repos/$Repository/pulls?state=all" `
        -Label 'Capability review pull requests')
    $pullCandidates = [System.Collections.Generic.List[object]]::new()
    foreach ($raw in $pullsRaw) {
        $body = [string](Get-PropertyValue -Value $raw -Name body `
            -Label 'Pull request inventory item' -AllowMissing)
        $head = Get-PropertyValue -Value $raw -Name head `
            -Label 'Pull request inventory item'
        $rawHeadBranch = [string](Get-PropertyValue -Value $head -Name ref `
            -Label 'Pull request inventory item head')
        $headRepository = Get-PropertyValue -Value $head -Name repo `
            -Label 'Pull request inventory item head' -AllowMissing
        $headRepositoryName = if ($null -ne $headRepository) {
            [string](Get-PropertyValue -Value $headRepository -Name full_name `
                -Label 'Pull request inventory item head repository')
        } else {
            ''
        }
        $user = Get-PropertyValue -Value $raw -Name user `
            -Label 'Pull request inventory item' -AllowMissing
        $creator = if ($null -ne $user) {
            Get-ActorRecord -User $user `
                -Label 'Capability review pull request creator'
        } else {
            $null
        }
        $hasMarker = $body.Contains($Marker)
        $usesCanonicalBranch = $rawHeadBranch -ceq $ExpectedBranch -and
            $headRepositoryName.ToLowerInvariant() -ceq $Repository
        $trustedCreator = $null -ne $creator -and
            (Test-IsProposalActor -Actor $creator)
        if (-not $trustedCreator -and -not $usesCanonicalBranch) {
            continue
        }
        if (-not $trustedCreator -and $usesCanonicalBranch) {
            throw 'The canonical capability-review branch has an untrusted pull-request owner.'
        }
        if ($trustedCreator -and -not $hasMarker -and -not $usesCanonicalBranch) {
            continue
        }
        if (-not $hasMarker) {
            throw 'The canonical capability-review branch is owned by an unmarked pull request.'
        }
        if (-not $usesCanonicalBranch) {
            throw 'A marked capability-review pull request uses a noncanonical branch.'
        }
        $binding = Get-ReviewBinding -Body $body -Marker $Marker -PullRequest
        Assert-GitSha -Value ([string]$binding.HandoffHead) `
            -Label 'Capability review pull-request handoff head'
        if ([long]$binding.ProposalActorId -ne [long]$creator.Id -or
            [string]$binding.ProposalActorLogin -cne [string]$creator.Login -or
            [long]$binding.IssueActorId -ne [long]$script:IssueActor.Id -or
            [string]$binding.IssueActorLogin -cne [string]$script:IssueActor.Login) {
            throw 'Capability review pull-request actor bindings do not match its dual authorities.'
        }
        Assert-CanonicalReviewBody -Body $body -Binding $binding `
            -Catalog $Catalog -PullRequest
        $base = Get-PropertyValue -Value $raw -Name base `
            -Label 'Capability review pull request'
        $state = [string](Get-PropertyValue -Value $raw -Name state `
            -Label 'Capability review pull request')
        $mergedAt = [string](Get-PropertyValue -Value $raw -Name merged_at `
            -Label 'Capability review pull request' -AllowMissing)
        $mergeCommit = [string](Get-PropertyValue -Value $raw `
            -Name merge_commit_sha -Label 'Capability review pull request' `
            -AllowMissing)
        $headSha = [string](Get-PropertyValue -Value $head -Name sha `
            -Label 'Capability review pull request head')
        Assert-GitSha -Value $headSha -Label 'Capability review pull-request head'
        if (-not [string]::IsNullOrWhiteSpace($mergeCommit)) {
            Assert-GitSha -Value $mergeCommit `
                -Label 'Capability review pull-request merge commit'
        }
        $pullCandidates.Add([pscustomobject][ordered]@{
            Number = [long](Get-PropertyValue -Value $raw -Name number `
                -Label 'Capability review pull request')
            State = if (-not [string]::IsNullOrWhiteSpace($mergedAt)) {
                'Merged'
            } elseif ($state -ceq 'open') {
                'Open'
            } else {
                'Closed'
            }
            IsDraft = [bool](Get-PropertyValue -Value $raw -Name draft `
                -Label 'Capability review pull request')
            Marker = $Marker
            HeadBranch = [string](Get-PropertyValue -Value $head -Name ref `
                -Label 'Capability review pull request head')
            HeadSha = $headSha
            BaseBranch = [string](Get-PropertyValue -Value $base -Name ref `
                -Label 'Capability review pull request base')
            BaseHead = [string]$binding.BaseHead
            IssueNumber = [long]$binding.IssueNumber
            MergeCommit = $mergeCommit
            MergedAt = $mergedAt
            Author = [string](Get-PropertyValue -Value (
                Get-PropertyValue -Value $raw -Name user `
                    -Label 'Capability review pull request'
            ) -Name login -Label 'Capability review pull request author')
            Binding = $binding
            Body = $body
            Creator = $creator
            HeadRepository = $headRepositoryName.ToLowerInvariant()
        })
    }
    if ($pullCandidates.Count -gt 1) {
        throw 'Canonical inventory contains a duplicate pull request.'
    }
    if ($issueCandidates.Count -eq 1 -and $pullCandidates.Count -eq 1) {
        if ([long]$pullCandidates[0].Binding.IssueNumber -ne
            [long]$issueCandidates[0].Number) {
            throw 'Capability review pull request binds another tracking issue.'
        }
        $issueBatch = @($issueCandidates[0].Binding.CapabilityBatch)
        $pullBatch = @($pullCandidates[0].Binding.CapabilityBatch)
        if ($issueBatch.Count -ne $pullBatch.Count) {
            throw 'Capability review issue and pull-request batches disagree.'
        }
        for ($index = 0; $index -lt $issueBatch.Count; $index++) {
            if ([string]$issueBatch[$index].Slug -cne
                    [string]$pullBatch[$index].Slug -or
                [string]$issueBatch[$index].DefinitionBlob -cne
                    [string]$pullBatch[$index].DefinitionBlob -or
                [string]$issueBatch[$index].Outcome -cne
                    [string]$pullBatch[$index].Outcome) {
                throw 'Capability review issue and pull-request batches disagree.'
            }
        }
    }

    $manifestCandidates = @()
    if ($branchCandidates.Count -eq 1) {
        $escapedRef = [Uri]::EscapeDataString(
            [string]$branchCandidates[0].HeadSha
        )
        $manifestRaw = Invoke-ReviewGitHub -Method GET `
            -Endpoint "repos/$Repository/contents/$($script:ManifestRelativePath)?ref=$escapedRef" `
            -AcceptNotFound
        if ($null -ne $manifestRaw) {
            $manifestCandidates = @(
                ConvertFrom-ManifestContent -ContentResponse $manifestRaw `
                    -Marker $Marker
            )
            if ([long]$manifestCandidates[0].ProposalActorId -ne
                    [long]$script:ProposalActor.Id -or
                [string]$manifestCandidates[0].ProposalActorLogin -cne
                    [string]$script:ProposalActor.Login -or
                [long]$manifestCandidates[0].IssueActorId -ne
                    [long]$script:IssueActor.Id -or
                [string]$manifestCandidates[0].IssueActorLogin -cne
                    [string]$script:IssueActor.Login) {
                throw 'Capability review manifest has untrusted dual actors.'
            }
        }
    }

    $bindings = [System.Collections.Generic.List[object]]::new()
    if ($issueCandidates.Count -eq 1) {
        $bindings.Add($issueCandidates[0].Binding)
    }
    if ($pullCandidates.Count -eq 1) {
        $bindings.Add($pullCandidates[0].Binding)
    }
    if ($manifestCandidates.Count -eq 1) {
        $bindings.Add([pscustomobject][ordered]@{
            CatalogDigest = $manifestCandidates[0].CatalogDigest
            BatchDigest = $manifestCandidates[0].BatchDigest
            BaseBranch = $manifestCandidates[0].BaseBranch
            BaseHead = $manifestCandidates[0].BaseHead
            BaseLedgerDigest = $manifestCandidates[0].BaseLedgerDigest
            Branch = $manifestCandidates[0].Branch
            LedgerPrefixCount = $manifestCandidates[0].LedgerPrefixCount
            ProposalActorId = $manifestCandidates[0].ProposalActorId
            ProposalActorLogin = $manifestCandidates[0].ProposalActorLogin
            IssueActorId = $manifestCandidates[0].IssueActorId
            IssueActorLogin = $manifestCandidates[0].IssueActorLogin
            IssueNumber = $manifestCandidates[0].IssueNumber
        })
    }
    $reviewBaseHead = ''
    if ($bindings.Count -gt 0) {
        $first = $bindings[0]
        foreach ($binding in @($bindings)) {
            if ([string]$binding.CatalogDigest -cne [string]$first.CatalogDigest -or
                [string]$binding.BatchDigest -cne [string]$first.BatchDigest -or
                [string]$binding.BaseBranch -cne [string]$first.BaseBranch -or
                [string]$binding.BaseHead -cne [string]$first.BaseHead -or
                [string]$binding.BaseLedgerDigest -cne
                    [string]$first.BaseLedgerDigest -or
                [string]$binding.Branch -cne [string]$first.Branch -or
                [int]$binding.LedgerPrefixCount -ne
                    [int]$first.LedgerPrefixCount -or
                [long]$binding.ProposalActorId -ne
                    [long]$first.ProposalActorId -or
                [string]$binding.ProposalActorLogin -cne
                    [string]$first.ProposalActorLogin -or
                [long]$binding.IssueActorId -ne
                    [long]$first.IssueActorId -or
                [string]$binding.IssueActorLogin -cne
                    [string]$first.IssueActorLogin) {
                throw 'Capability review inventory bindings disagree.'
            }
        }
        $reviewBaseHead = [string]$first.BaseHead
    }
    elseif ($branchCandidates.Count -eq 1) {
        if ([string]$branchCandidates[0].HeadSha -cne $CurrentDefaultHead) {
            throw 'Interrupted branch-first inventory has no recoverable exact base.'
        }
        $reviewBaseHead = $CurrentDefaultHead
    }
    else {
        $reviewBaseHead = $CurrentDefaultHead
    }
    Assert-GitSha -Value $reviewBaseHead -Label 'Capability review base head'
    if ($branchCandidates.Count -eq 1) {
        $branchCandidates[0].BaseHead = $reviewBaseHead
    }

    return [pscustomobject][ordered]@{
        Issues = @($issueCandidates)
        Branches = @($branchCandidates)
        PullRequests = @($pullCandidates)
        Manifests = @($manifestCandidates)
        Binding = if ($bindings.Count -gt 0) { $bindings[0] } else { $null }
        ReviewBaseHead = $reviewBaseHead
        CurrentDefaultHead = $CurrentDefaultHead
        HistoricalIssues = @($historicalIssueCandidates)
        Source = 'GitHub'
    }
}

function Test-LocalAncestor {
    param(
        [Parameter(Mandatory)][string]$Ancestor,
        [Parameter(Mandatory)][string]$Descendant
    )

    $result = Invoke-ReviewGit -Arguments @(
        '-C', $ConsumerRoot, 'merge-base', '--is-ancestor', $Ancestor, $Descendant
    ) -AllowedExitCodes @(0, 1)
    return $result.ExitCode -eq 0
}

function Get-RemoteRepositoryIdentity {
    param([Parameter(Mandatory)][string]$RemoteUrl)

    $value = $RemoteUrl.Trim()
    $path = ''
    $uri = $null
    if ([Uri]::TryCreate($value, [UriKind]::Absolute, [ref]$uri) -and
        $uri.Host.Equals('github.com', [StringComparison]::OrdinalIgnoreCase)) {
        $path = $uri.AbsolutePath.Trim('/')
    }
    elseif ($value -match '^(?:[^@]+@)?github\.com:(?<path>[^?#]+)$') {
        $path = [string]$Matches.path
    }
    if ($path.EndsWith('.git', [StringComparison]::OrdinalIgnoreCase)) {
        $path = $path.Substring(0, $path.Length - 4)
    }
    if ($path -notmatch '^[^/]+/[^/]+$') {
        throw 'Consumer origin is not one canonical GitHub repository remote.'
    }
    return $path.ToLowerInvariant()
}

function Import-HistoricalProtocolCatalog {
    param([Parameter(Mandatory)][string]$ProtocolCommit)

    $indexBytes = Get-ProtocolGitBlobBytes -CommitSha $ProtocolCommit `
        -RelativePath 'capabilities/index.json'
    $indexText = ConvertFrom-StrictUtf8Bytes -Bytes $indexBytes `
        -Label 'Historical capability catalog index'
    try {
        $index = $indexText | ConvertFrom-Json
    }
    catch {
        throw 'Historical capability catalog index is not valid JSON.'
    }
    if ($null -eq $index -or $index.capabilities -isnot [Array] -or
        @($index.capabilities).Count -eq 0) {
        throw 'Historical capability catalog index is not canonical.'
    }

    $temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) (
        'meandai-historical-catalog-' + [Guid]::NewGuid().ToString('N')
    )
    [void](New-Item -ItemType Directory -Path $temporaryRoot)
    try {
        [IO.File]::WriteAllBytes(
            (Join-Path $temporaryRoot 'index.json'),
            [byte[]]$indexBytes
        )
        $seen = [System.Collections.Generic.HashSet[string]]::new(
            [StringComparer]::Ordinal
        )
        foreach ($entry in @($index.capabilities)) {
            $slug = [string](Get-PropertyValue -Value $entry -Name slug `
                -Label 'Historical capability catalog entry')
            $definition = [string](Get-PropertyValue -Value $entry `
                -Name definition -Label 'Historical capability catalog entry')
            if ($slug -cnotmatch '^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$' -or
                $definition -cne "$slug.json" -or -not $seen.Add($definition)) {
                throw 'Historical capability catalog contains a noncanonical definition path.'
            }
            $definitionBytes = Get-ProtocolGitBlobBytes `
                -CommitSha $ProtocolCommit `
                -RelativePath "capabilities/$definition"
            [IO.File]::WriteAllBytes(
                (Join-Path $temporaryRoot $definition),
                [byte[]]$definitionBytes
            )
        }
        try {
            return Import-MeAndAICapabilityCatalog -IndexPath (
                Join-Path $temporaryRoot 'index.json'
            )
        }
        catch {
            throw "Historical capability catalog is invalid. $($_.Exception.Message)"
        }
    }
    finally {
        $resolvedTemporary = [IO.Path]::GetFullPath($temporaryRoot)
        $temporaryBase = [IO.Path]::GetFullPath(
            [IO.Path]::GetTempPath()
        ).TrimEnd(
            [IO.Path]::DirectorySeparatorChar,
            [IO.Path]::AltDirectorySeparatorChar
        ) + [IO.Path]::DirectorySeparatorChar
        if ($resolvedTemporary.StartsWith(
            $temporaryBase,
            [StringComparison]::OrdinalIgnoreCase
        ) -and (Test-Path -LiteralPath $resolvedTemporary -PathType Container)) {
            Remove-Item -LiteralPath $resolvedTemporary -Recurse -Force
        }
    }
}

function Get-HistoricalProtocolEvidence {
    param(
        [Parameter(Mandatory)]$HistoricalIssue,
        [Parameter(Mandatory)]$CurrentCatalog,
        [Parameter(Mandatory)][string]$CurrentDefaultHead
    )

    $baseHead = [string]$HistoricalIssue.Binding.BaseHead
    if (-not (Test-LocalAncestor -Ancestor $baseHead `
        -Descendant $CurrentDefaultHead)) {
        throw 'Historical capability-review base is not contained by the current default branch.'
    }
    $gitlink = Invoke-ReviewGit -Arguments @(
        '-C', $ConsumerRoot, 'ls-tree', $baseHead, '--', '.ai/protocol'
    )
    if ($gitlink.ExitCode -ne 0 -or
        $gitlink.Text -cnotmatch
            '^160000 commit (?<sha>[0-9a-f]{40})\t\.ai/protocol$') {
        throw 'Historical capability-review BaseHead lacks one canonical protocol gitlink.'
    }
    $protocolCommit = [string]$Matches['sha']
    Assert-GitSha -Value $protocolCommit -Label 'Historical protocol gitlink'

    $protocolOrigin = (Invoke-ReviewGit -Arguments @(
        '-C', $ProtocolRoot, 'remote', 'get-url', 'origin'
    )).Text
    if ((Get-RemoteRepositoryIdentity -RemoteUrl $protocolOrigin) -cne
        $script:ProtocolRepository.ToLowerInvariant()) {
        throw 'Historical protocol checkout origin is not the canonical meAndAI repository.'
    }
    $commitExists = Invoke-ReviewGit -Arguments @(
        '-C', $ProtocolRoot, 'cat-file', '-e', "${protocolCommit}^{commit}"
    ) -AllowedExitCodes @(0, 1)
    if ($commitExists.ExitCode -ne 0) {
        throw 'Historical protocol gitlink does not identify an available commit.'
    }
    $ancestor = Invoke-ReviewGit -Arguments @(
        '-C', $ProtocolRoot, 'merge-base', '--is-ancestor',
        $protocolCommit, 'HEAD'
    ) -AllowedExitCodes @(0, 1)
    if ($ancestor.ExitCode -ne 0) {
        throw 'Historical protocol commit is not an ancestor of the current protocol release.'
    }

    $versionBytes = Get-ProtocolGitBlobBytes -CommitSha $protocolCommit `
        -RelativePath 'VERSION'
    $versionText = ConvertFrom-StrictUtf8Bytes -Bytes $versionBytes `
        -Label 'Historical protocol VERSION'
    if ($versionText -cnotmatch
        '^(?<version>(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*))\n$') {
        throw 'Historical protocol VERSION is not canonical.'
    }
    $protocolTag = "v$([string]$Matches['version'])"
    $tagCommit = Invoke-ReviewGit -Arguments @(
        '-C', $ProtocolRoot, 'rev-parse', '--verify',
        "refs/tags/${protocolTag}^{commit}"
    ) -AllowedExitCodes @(0, 1)
    if ($tagCommit.ExitCode -ne 0 -or $tagCommit.Text -cne $protocolCommit) {
        throw 'Historical protocol commit does not have its exact immutable version tag.'
    }

    $escapedTag = [Uri]::EscapeDataString($protocolTag)
    $release = Invoke-ReviewGitHub -Method GET `
        -Endpoint "repos/$($script:ProtocolRepository)/releases/tags/$escapedTag" `
        -Authority Protocol
    [DateTimeOffset]$publishedAt = [DateTimeOffset]::MinValue
    if ([string](Get-PropertyValue -Value $release -Name tag_name `
            -Label 'Historical protocol release') -cne $protocolTag -or
        (Get-PropertyValue -Value $release -Name draft `
            -Label 'Historical protocol release') -isnot [bool] -or
        [bool]$release.draft -or
        (Get-PropertyValue -Value $release -Name prerelease `
            -Label 'Historical protocol release') -isnot [bool] -or
        [bool]$release.prerelease -or
        (Get-PropertyValue -Value $release -Name immutable `
            -Label 'Historical protocol release') -isnot [bool] -or
        -not [bool]$release.immutable -or
        -not [DateTimeOffset]::TryParse(
            [string](Get-PropertyValue -Value $release -Name published_at `
                -Label 'Historical protocol release'),
            [ref]$publishedAt
        )) {
        throw 'Historical protocol tag is not one exact published immutable release.'
    }

    $historicalCatalog = Import-HistoricalProtocolCatalog `
        -ProtocolCommit $protocolCommit
    if ([string]$historicalCatalog.CatalogDigest -cne
            [string]$HistoricalIssue.CatalogDigest -or
        [string]$historicalCatalog.CatalogDigest -cne
            [string]$HistoricalIssue.Binding.CatalogDigest) {
        throw 'Historical capability-review marker does not match its immutable release catalog.'
    }
    Assert-MeAndAICapabilityCatalogExtension `
        -CurrentCatalog $historicalCatalog -TargetCatalog $CurrentCatalog
    if (@($historicalCatalog.Capabilities).Count -ge
        @($CurrentCatalog.Capabilities).Count) {
        throw 'Historical capability catalog is not a strict predecessor prefix.'
    }
    return [pscustomobject][ordered]@{
        Commit = $protocolCommit
        Tag = $protocolTag
        Catalog = $historicalCatalog
        Marker = [string]$HistoricalIssue.Marker
        Branch = 'automation/meandai-capability-review-' +
            $historicalCatalog.CatalogDigest.Substring(0, 16)
    }
}

function Assert-ProductionCheckout {
    $repositoryResponse = Invoke-ReviewGitHub -Method GET `
        -Endpoint "repos/$Repository"
    $repositoryId = [long](Get-PropertyValue -Value $repositoryResponse `
        -Name id -Label 'GitHub repository')
    $repositoryName = [string](Get-PropertyValue -Value $repositoryResponse `
        -Name full_name -Label 'GitHub repository')
    $repositoryDefault = [string](Get-PropertyValue -Value $repositoryResponse `
        -Name default_branch -Label 'GitHub repository')
    if ($repositoryId -le 0 -or
        $repositoryName.ToLowerInvariant() -cne $Repository -or
        $repositoryDefault -cne $DefaultBranch) {
        throw 'GitHub repository identity/default branch does not match the runner target.'
    }
    $repositoryOwnerResponse = Get-PropertyValue -Value $repositoryResponse `
        -Name owner -Label 'GitHub repository'
    $repositoryOwner = Get-ActorRecord -User $repositoryOwnerResponse `
        -Label 'GitHub repository owner'
    $repositoryOwnerType = [string](Get-PropertyValue `
        -Value $repositoryOwnerResponse -Name type `
        -Label 'GitHub repository owner')
    if (@('User', 'Organization') -cnotcontains $repositoryOwnerType) {
        throw 'GitHub repository owner type is unsupported.'
    }
    $script:RepositoryOwner = [pscustomobject][ordered]@{
        Id = [long]$repositoryOwner.Id
        Login = [string]$repositoryOwner.Login
        Type = $repositoryOwnerType
    }
    $proposalActorResponse = Invoke-ReviewGitHub -Method GET -Endpoint 'user'
    $script:ProposalActor = Get-ActorRecord -User $proposalActorResponse `
        -Label 'Authenticated proposal actor'
    if ([string]::IsNullOrWhiteSpace($IssueActorLogin)) {
        throw 'IssueActorLogin is required for issue-token-compatible ownership.'
    }
    $issueActorResponse = Invoke-ReviewGitHub -Method GET `
        -Endpoint "users/$([Uri]::EscapeDataString($IssueActorLogin))"
    $script:IssueActor = Get-ActorRecord -User $issueActorResponse `
        -Label 'Configured issue actor'
    if ([string]$script:IssueActor.Login -cne $IssueActorLogin) {
        throw 'Configured issue actor login does not resolve exactly.'
    }

    $top = Invoke-ReviewGit -Arguments @(
        '-C', $ConsumerRoot, 'rev-parse', '--show-toplevel'
    )
    $topPath = [IO.Path]::GetFullPath($top.Text).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $expected = [IO.Path]::GetFullPath($ConsumerRoot).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    if (-not $topPath.Equals($expected, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'ConsumerRoot is not the exact checkout root.'
    }
    $origin = (Invoke-ReviewGit -Arguments @(
        '-C', $ConsumerRoot, 'remote', 'get-url', 'origin'
    )).Text
    if ((Get-RemoteRepositoryIdentity -RemoteUrl $origin) -cne $Repository) {
        throw 'Consumer origin does not match the exact GitHub repository.'
    }
    $managedStatus = (Invoke-ReviewGit -Arguments @(
        '-C', $ConsumerRoot, 'status', '--porcelain=v1',
        '--untracked-files=all', '--',
        $script:LedgerRelativePath, $script:ManifestRelativePath
    )).Text
    if (-not [string]::IsNullOrWhiteSpace($managedStatus)) {
        throw 'Capability ledger or review manifest is dirty outside exact HEAD.'
    }
    $head = (Invoke-ReviewGit -Arguments @(
        '-C', $ConsumerRoot, 'rev-parse', 'HEAD'
    )).Text
    Assert-GitSha -Value $head -Label 'Checked-out consumer head'

    $branchResponse = Invoke-ReviewGitHub -Method GET `
        -Endpoint "repos/$Repository/branches/$([Uri]::EscapeDataString($DefaultBranch))"
    $commit = Get-PropertyValue -Value $branchResponse -Name commit `
        -Label 'Default branch'
    $remoteHead = [string](Get-PropertyValue -Value $commit -Name sha `
        -Label 'Default branch')
    Assert-GitSha -Value $remoteHead -Label 'Remote default-branch head'
    if ($head -cne $remoteHead) {
        throw 'Consumer checkout is not the exact remote default-branch head.'
    }
    return [pscustomobject][ordered]@{
        Head = $head
        RepositoryId = $repositoryId
        ProposalActor = $script:ProposalActor
        IssueActor = $script:IssueActor
    }
}

function Assert-LiveDefaultHeadUnchanged {
    $branchResponse = Invoke-ReviewGitHub -Method GET `
        -Endpoint "repos/$Repository/branches/$([Uri]::EscapeDataString($DefaultBranch))"
    $commit = Get-PropertyValue -Value $branchResponse -Name commit `
        -Label 'Live default branch'
    $remoteHead = [string](Get-PropertyValue -Value $commit -Name sha `
        -Label 'Live default branch')
    Assert-GitSha -Value $remoteHead -Label 'Live default-branch head'
    if ($remoteHead -cne $DefaultHead) {
        throw 'Default branch changed after capability finalization proof.'
    }
    $localHead = (Invoke-ReviewGit -Arguments @(
        '-C', $ConsumerRoot, 'rev-parse', 'HEAD'
    )).Text
    if ($localHead -cne $DefaultHead) {
        throw 'Consumer checkout changed after capability finalization proof.'
    }
    $managedStatus = (Invoke-ReviewGit -Arguments @(
        '-C', $ConsumerRoot, 'status', '--porcelain=v1',
        '--untracked-files=all', '--',
        $script:LedgerRelativePath, $script:ManifestRelativePath
    )).Text
    if (-not [string]::IsNullOrWhiteSpace($managedStatus)) {
        throw 'Capability evidence changed after capability finalization proof.'
    }
}

function Test-ExactGitHubPullReviewAuthority {
    param(
        [AllowEmptyString()][string]$Authority,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][long]$PullRequestNumber
    )

    if ($Repository -cnotmatch
            '^[a-z0-9](?:[a-z0-9-]{0,38})/[a-z0-9._-]+$' -or
        $PullRequestNumber -le 0) {
        return $false
    }
    $authorityMatch = [regex]::Match(
        $Authority,
        '^https://github\.com/(?<owner>[A-Za-z0-9](?:[A-Za-z0-9-]{0,38}))/(?<repository>[A-Za-z0-9._-]+)/pull/(?<number>[1-9][0-9]*)$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if (-not $authorityMatch.Success) {
        return $false
    }
    $expectedParts = $Repository.Split('/')
    if (-not $authorityMatch.Groups['owner'].Value.Equals(
            $expectedParts[0],
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        -not $authorityMatch.Groups['repository'].Value.Equals(
            $expectedParts[1],
            [StringComparison]::OrdinalIgnoreCase
        )) {
        return $false
    }
    [long]$authorityPullRequestNumber = 0
    return [long]::TryParse(
        $authorityMatch.Groups['number'].Value,
        [ref]$authorityPullRequestNumber
    ) -and $authorityPullRequestNumber -eq $PullRequestNumber
}

function Assert-MergedReview {
    param(
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)]$Ledger,
        [Parameter(Mandatory)][int]$LedgerPrefixCount
    )

    $reviews = @(Get-PagedGitHubCollection `
        -Endpoint "repos/$Repository/pulls/$($PullRequest.Number)/reviews" `
        -Label 'Capability review approvals')
    $latestByReviewer = @{}
    foreach ($review in $reviews) {
        $user = Get-PropertyValue -Value $review -Name user `
            -Label 'Capability review approval'
        $login = [string](Get-PropertyValue -Value $user -Name login `
            -Label 'Capability review approval')
        $submittedAt = [string](Get-PropertyValue -Value $review `
            -Name submitted_at -Label 'Capability review approval' -AllowMissing)
        $key = $login.ToLowerInvariant()
        if (-not $latestByReviewer.ContainsKey($key) -or
            [string]$latestByReviewer[$key].submitted_at -lt $submittedAt) {
            $latestByReviewer[$key] = $review
        }
    }
    $approved = @($latestByReviewer.Values | Where-Object {
        [string]$_.state -ceq 'APPROVED' -and
        [string]$_.commit_id -ceq [string]$PullRequest.HeadSha
    })
    if ($approved.Count -eq 0 -and $reviews.Count -gt 0) {
        throw 'Merged capability review lacks an approval for the exact review head.'
    }
    $trustedReviewer = $null
    if ($reviews.Count -gt 0) {
        foreach ($review in @($approved | Sort-Object {
            [string]$_.user.login
        })) {
            $reviewer = Get-ActorRecord -User $review.user `
                -Label 'Capability review approving reviewer'
            if ([long]$reviewer.Id -eq [long]$PullRequest.Creator.Id) {
                continue
            }
            $permission = Get-CollaboratorPermission -Login $reviewer.Login `
                -ExpectedId ([long]$reviewer.Id)
            if (@('write', 'maintain', 'admin') -ccontains $permission) {
                $trustedReviewer = [pscustomobject][ordered]@{
                    Id = [long]$reviewer.Id
                    Login = [string]$reviewer.Login
                    Permission = $permission
                    Commit = [string]$review.commit_id
                }
                break
            }
        }
    }
    else {
        $trustedReviewer = Get-ExactHeadOwnerAttestation `
            -PullRequest $PullRequest
    }
    if ($null -eq $trustedReviewer) {
        if ($reviews.Count -gt 0) {
            throw 'Merged capability review lacks trusted maintainer approval.'
        }
        throw 'Merged capability review lacks an exact-head personal-owner attestation.'
    }

    $pullIdentity = "pull-request:$($PullRequest.Number)"
    $entries = @($Ledger.Entries)
    if ($LedgerPrefixCount -lt 0 -or $LedgerPrefixCount -ge $entries.Count) {
        throw 'Merged capability review has an invalid ledger-prefix binding.'
    }
    foreach ($entry in @($entries | Select-Object -Skip $LedgerPrefixCount)) {
        if ([string]$entry.ReviewIdentity -cne $pullIdentity -or
            -not (Test-ExactGitHubPullReviewAuthority `
                -Authority ([string]$entry.ReviewAuthority) `
                -Repository $Repository `
                -PullRequestNumber ([long]$PullRequest.Number))) {
            throw 'Merged capability review terminal ledger is not linked to the exact pull request.'
        }
    }
    return $trustedReviewer
}

function New-PlanFromBinding {
    param(
        [Parameter(Mandatory)]$Binding,
        [Parameter(Mandatory)]$Catalog,
        [Parameter(Mandatory)][string]$Marker
    )

    $catalogBatch = @($Catalog.Capabilities | Select-Object `
        -Skip ([int]$Binding.LedgerPrefixCount))
    $bindingBatch = @($Binding.CapabilityBatch)
    if ($catalogBatch.Count -ne $bindingBatch.Count) {
        throw 'Capability review provenance batch is not the catalog suffix.'
    }
    $batch = [System.Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt $catalogBatch.Count; $index++) {
        if ([string]$catalogBatch[$index].Slug -cne
                [string]$bindingBatch[$index].Slug -or
            [string]$catalogBatch[$index].DefinitionBlob -cne
                [string]$bindingBatch[$index].DefinitionBlob) {
            throw 'Capability review provenance changed immutable catalog identity.'
        }
        $batch.Add([pscustomobject][ordered]@{
            Slug = [string]$catalogBatch[$index].Slug
            DefinitionBlob = [string]$catalogBatch[$index].DefinitionBlob
            Type = [string]$catalogBatch[$index].Type
            Outcome = [string]$bindingBatch[$index].Outcome
        })
    }
    return [pscustomobject][ordered]@{
        Marker = $Marker
        Repository = $Repository
        CatalogDigest = [string]$Binding.CatalogDigest
        BatchDigest = [string]$Binding.BatchDigest
        BaseBranch = [string]$Binding.BaseBranch
        BaseHead = [string]$Binding.BaseHead
        Branch = [string]$Binding.Branch
        CapabilityBatch = @($batch)
    }
}

function Assert-ExactLedgerContent {
    param(
        [Parameter(Mandatory)]$Content,
        [AllowNull()][byte[]]$ExpectedBytes,
        [Parameter(Mandatory)][string]$Label
    )

    if ($null -eq $ExpectedBytes) {
        if ([bool]$Content.Exists) {
            throw "$Label must be absent."
        }
        return
    }
    if (-not [bool]$Content.Exists -or
        -not (Test-BytesEqual -Left ([byte[]]$Content.Bytes) `
            -Right $ExpectedBytes)) {
        throw "$Label does not byte-match canonical ledger evidence."
    }
}

function Assert-MergedTreeEvidence {
    param(
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)]$Binding,
        [Parameter(Mandatory)]$Catalog,
        [Parameter(Mandatory)]$Ledger,
        [Parameter(Mandatory)][byte[]]$CurrentLedgerBytes,
        [AllowNull()][byte[]]$ReviewedLedgerBytes = $null,
        [AllowNull()]$CurrentCatalog = $null,
        [Parameter(Mandatory)][string]$Marker,
        [Parameter(Mandatory)][string]$CurrentDefaultHead
    )

    if ($null -eq $ReviewedLedgerBytes) {
        $ReviewedLedgerBytes = $CurrentLedgerBytes
    }
    if ($null -eq $CurrentCatalog) {
        $CurrentCatalog = $Catalog
    }

    Assert-GitSha -Value ([string]$PullRequest.HeadSha) `
        -Label 'Merged capability review head'
    Assert-GitSha -Value ([string]$PullRequest.MergeCommit) `
        -Label 'Merged capability review merge commit'
    Assert-GitSha -Value ([string]$Binding.BaseHead) `
        -Label 'Merged capability review base head'
    Assert-GitSha -Value ([string]$Binding.HandoffHead) `
        -Label 'Merged capability review handoff head'

    $prefixCount = [int]$Binding.LedgerPrefixCount
    $entries = @($Ledger.Entries)
    if ($prefixCount -lt 0 -or $prefixCount -ge $entries.Count) {
        throw 'Merged capability review provenance has invalid ledger prefix.'
    }
    $baseBytes = if ([string]$Binding.BaseLedgerDigest -ceq 'missing') {
        if ($prefixCount -ne 0) {
            throw 'Missing base ledger cannot bind a nonempty ledger prefix.'
        }
        $null
    }
    else {
        $bytes = ConvertTo-MeAndAICapabilityLedgerBytes -Catalog $Catalog `
            -Entries @($entries | Select-Object -First $prefixCount)
        if ((Get-Sha256Bytes -Bytes $bytes) -cne
            [string]$Binding.BaseLedgerDigest) {
            throw 'Merged capability review base-ledger digest changed.'
        }
        [byte[]]$bytes
    }

    $baseLedger = Get-GitHubFileAtRef -RelativePath $script:LedgerRelativePath `
        -Ref ([string]$Binding.BaseHead) -AllowMissing
    Assert-ExactLedgerContent -Content $baseLedger -ExpectedBytes $baseBytes `
        -Label 'Base-tree capability ledger'
    $baseManifest = Get-GitHubFileAtRef `
        -RelativePath $script:ManifestRelativePath `
        -Ref ([string]$Binding.BaseHead) -AllowMissing
    if ([bool]$baseManifest.Exists) {
        throw 'Capability review transient manifest already existed on the bound base.'
    }
    $handoffLedger = Get-GitHubFileAtRef `
        -RelativePath $script:LedgerRelativePath `
        -Ref ([string]$Binding.HandoffHead) -AllowMissing
    Assert-ExactLedgerContent -Content $handoffLedger -ExpectedBytes $baseBytes `
        -Label 'Handoff-tree capability ledger'

    $handoffManifestContent = Get-GitHubFileAtRef `
        -RelativePath $script:ManifestRelativePath `
        -Ref ([string]$Binding.HandoffHead)
    $manifestResponse = [pscustomobject][ordered]@{
        encoding = 'base64'
        content = [Convert]::ToBase64String(
            [byte[]]$handoffManifestContent.Bytes
        )
    }
    $handoffManifest = ConvertFrom-ManifestContent `
        -ContentResponse $manifestResponse -Marker $Marker
    $boundPlan = New-PlanFromBinding -Binding $Binding -Catalog $Catalog `
        -Marker $Marker
    $savedDigest = $script:BaseLedgerDigest
    try {
        $script:BaseLedgerDigest = [string]$Binding.BaseLedgerDigest
        Assert-CanonicalManifest -Manifest $handoffManifest -Plan $boundPlan `
            -Catalog $Catalog -LedgerPrefixCount $prefixCount
    }
    finally {
        $script:BaseLedgerDigest = $savedDigest
    }
    if ([long]$handoffManifest.IssueNumber -ne [long]$Binding.IssueNumber) {
        throw 'Handoff manifest does not bind the canonical tracking issue.'
    }

    $handoffCommit = Invoke-ReviewGitHub -Method GET `
        -Endpoint "repos/$Repository/git/commits/$($Binding.HandoffHead)"
    $handoffParents = @((Get-PropertyValue -Value $handoffCommit `
        -Name parents -Label 'Capability review handoff commit'))
    if ($handoffParents.Count -ne 1 -or
        [string]$handoffParents[0].sha -cne [string]$Binding.BaseHead) {
        throw 'Capability review handoff commit is not the direct child of its bound base.'
    }
    $handoffCompare = Invoke-ReviewGitHub -Method GET `
        -Endpoint "repos/$Repository/compare/$($Binding.BaseHead)...$($Binding.HandoffHead)"
    $handoffFiles = @((Get-PropertyValue -Value $handoffCompare -Name files `
        -Label 'Capability review handoff comparison'))
    if ($handoffFiles.Count -ne 1 -or
        [string]$handoffFiles[0].filename -cne $script:ManifestRelativePath) {
        throw 'Capability review handoff commit was not manifest-only.'
    }

    $commits = @(Get-PagedGitHubCollection `
        -Endpoint "repos/$Repository/pulls/$($PullRequest.Number)/commits" `
        -Label 'Capability review pull-request commits')
    if ($commits.Count -lt 1) {
        throw 'Capability review pull request has no reviewed commits.'
    }
    $commitShas = @($commits | ForEach-Object {
        [string](Get-PropertyValue -Value $_ -Name sha `
            -Label 'Capability review pull-request commit')
    })
    foreach ($sha in $commitShas) {
        Assert-GitSha -Value $sha -Label 'Capability review pull-request commit'
    }
    if (@($commitShas | Where-Object {
        $_ -ceq [string]$Binding.HandoffHead
    }).Count -ne 1 -or
        [string]$commitShas[-1] -cne [string]$PullRequest.HeadSha) {
        throw 'Reviewed pull-request commits do not contain the exact handoff-to-head chain.'
    }

    foreach ($tree in @(
        [pscustomobject]@{
            Ref = [string]$PullRequest.HeadSha
            Label = 'review head'
            ExpectedBytes = [byte[]]$ReviewedLedgerBytes
            LedgerCatalog = $Catalog
        },
        [pscustomobject]@{
            Ref = [string]$PullRequest.MergeCommit
            Label = 'merge commit'
            ExpectedBytes = [byte[]]$ReviewedLedgerBytes
            LedgerCatalog = $Catalog
        },
        [pscustomobject]@{
            Ref = $CurrentDefaultHead
            Label = 'default head'
            ExpectedBytes = [byte[]]$CurrentLedgerBytes
            LedgerCatalog = $CurrentCatalog
        }
    )) {
        $treeLedger = Get-GitHubFileAtRef `
            -RelativePath $script:LedgerRelativePath -Ref $tree.Ref
        Assert-ExactLedgerContent -Content $treeLedger `
            -ExpectedBytes ([byte[]]$tree.ExpectedBytes) `
            -Label "$($tree.Label) capability ledger"
        [void](Import-MeAndAICapabilityLedger -Catalog $tree.LedgerCatalog `
            -Bytes ([byte[]]$treeLedger.Bytes))
        $treeManifest = Get-GitHubFileAtRef `
            -RelativePath $script:ManifestRelativePath -Ref $tree.Ref `
            -AllowMissing
        if ([bool]$treeManifest.Exists) {
            throw "Transient capability-review manifest remains on $($tree.Label)."
        }
    }
}

function Resolve-HistoricalCapabilityReviewRecovery {
    param(
        [Parameter(Mandatory)]$HistoricalIssue,
        [Parameter(Mandatory)]$CurrentCatalog,
        [Parameter(Mandatory)]$CurrentLedger,
        [Parameter(Mandatory)][byte[]]$CurrentLedgerBytes,
        [Parameter(Mandatory)][string]$CurrentDefaultHead
    )

    $protocolEvidence = Get-HistoricalProtocolEvidence `
        -HistoricalIssue $HistoricalIssue -CurrentCatalog $CurrentCatalog `
        -CurrentDefaultHead $CurrentDefaultHead
    $historicalCatalog = $protocolEvidence.Catalog
    $historicalInventory = Get-ProductionInventory `
        -Catalog $historicalCatalog -Marker $protocolEvidence.Marker `
        -ExpectedBranch $protocolEvidence.Branch `
        -CurrentDefaultHead $CurrentDefaultHead -SkipStaleCatalogGuard

    if (@($historicalInventory.Issues).Count -ne 1 -or
        [long]$historicalInventory.Issues[0].Number -ne
            [long]$HistoricalIssue.Number -or
        [string]$historicalInventory.Issues[0].Body -cne
            [string]$HistoricalIssue.Body) {
        throw 'Historical capability-review inventory does not contain one exact issue.'
    }
    $pulls = @($historicalInventory.PullRequests)
    if ($pulls.Count -ne 1) {
        throw 'Historical capability-review inventory does not contain one exact pull request.'
    }
    $pullRequest = $pulls[0]
    if ($FinalizePullRequestNumber -gt 0 -and
        [long]$pullRequest.Number -ne $FinalizePullRequestNumber) {
        throw 'The requested finalization pull request is not the exact canonical review.'
    }
    if ([string]$pullRequest.State -ceq 'Open') {
        throw 'An active historical capability review cannot be recovered.'
    }
    if ([string]$pullRequest.State -ceq 'Closed') {
        throw 'Historical capability-review pull request closed without merge.'
    }
    if ([string]$pullRequest.State -cne 'Merged') {
        throw 'Historical capability-review pull request state is ambiguous.'
    }
    $binding = $pullRequest.Binding
    if ($null -eq $binding) {
        throw 'Historical capability-review pull request lacks its canonical binding.'
    }

    $historicalCount = @($historicalCatalog.Capabilities).Count
    $currentEntries = @($CurrentLedger.Entries)
    if ($currentEntries.Count -lt $historicalCount) {
        throw 'Current capability ledger truncates the historical reviewed prefix.'
    }
    $historicalLedgerBytes = ConvertTo-MeAndAICapabilityLedgerBytes `
        -Catalog $historicalCatalog `
        -Entries @($currentEntries | Select-Object -First $historicalCount)
    $reviewLedgerContent = Get-GitHubFileAtRef `
        -RelativePath $script:LedgerRelativePath `
        -Ref ([string]$pullRequest.HeadSha)
    Assert-ExactLedgerContent -Content $reviewLedgerContent `
        -ExpectedBytes ([byte[]]$historicalLedgerBytes) `
        -Label 'review head capability ledger'
    $historicalLedger = Import-MeAndAICapabilityLedger `
        -Catalog $historicalCatalog `
        -Bytes ([byte[]]$reviewLedgerContent.Bytes)
    if (@($historicalLedger.Entries).Count -ne $historicalCount) {
        throw 'Historical merged capability review lacks one complete catalog ledger.'
    }

    try {
        $verifiedReviewer = Assert-MergedReview -PullRequest $pullRequest `
            -Ledger $historicalLedger `
            -LedgerPrefixCount ([int]$binding.LedgerPrefixCount)
    }
    catch {
        throw "Historical capability review lacks current exact-head approval or owner attestation. $($_.Exception.Message)"
    }
    Assert-MergedTreeEvidence -PullRequest $pullRequest -Binding $binding `
        -Catalog $historicalCatalog -Ledger $historicalLedger `
        -CurrentLedgerBytes $CurrentLedgerBytes `
        -ReviewedLedgerBytes $historicalLedgerBytes `
        -CurrentCatalog $CurrentCatalog -Marker $protocolEvidence.Marker `
        -CurrentDefaultHead $CurrentDefaultHead

    $defaultContainsMerge = Test-LocalAncestor `
        -Ancestor ([string]$pullRequest.MergeCommit) `
        -Descendant $CurrentDefaultHead
    if (-not $defaultContainsMerge) {
        throw 'Historical merged capability review is not contained by the current default branch.'
    }
    $branch = if (@($historicalInventory.Branches).Count -eq 1) {
        $historicalInventory.Branches[0]
    }
    else {
        $null
    }
    $plan = Resolve-MeAndAICapabilityReviewFinalization `
        -Catalog $historicalCatalog -Ledger $historicalLedger `
        -Repository $Repository -DefaultBranch $DefaultBranch `
        -Marker $protocolEvidence.Marker `
        -ExpectedBranch $protocolEvidence.Branch `
        -ExpectedBaseHead ([string]$binding.BaseHead) `
        -ExpectedReviewHead ([string]$pullRequest.HeadSha) `
        -Issue $historicalInventory.Issues[0] -Branch $branch `
        -PullRequest $pullRequest `
        -DefaultContainsMerge:$defaultContainsMerge `
        -ManifestPresentOnDefault:$false
    return [pscustomobject][ordered]@{
        Plan = $plan
        Catalog = $historicalCatalog
        Inventory = $historicalInventory
        Issue = $historicalInventory.Issues[0]
        PullRequest = $pullRequest
        VerifiedReviewer = $verifiedReviewer
    }
}

function Remove-ReviewBranchWithLease {
    param(
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][string]$ExpectedHead
    )

    Assert-GitSha -Value $ExpectedHead `
        -Label 'Capability-review branch expected head'
    Assert-LiveDefaultHeadUnchanged
    $escapedBranch = ConvertTo-GitRefEndpointPath -RefName $Branch
    $endpoint = "repos/$Repository/git/ref/heads/$escapedBranch"
    $remote = Invoke-ReviewGitHub -Method GET -Endpoint $endpoint `
        -AcceptNotFound
    if ($null -eq $remote) {
        return
    }
    $object = Get-PropertyValue -Value $remote -Name object `
        -Label 'Finalization branch'
    $actualHead = [string](Get-PropertyValue -Value $object -Name sha `
        -Label 'Finalization branch')
    if ($actualHead -cne $ExpectedHead) {
        throw 'Finalization branch changed after exact-head verification.'
    }
    $lease = "--force-with-lease=refs/heads/${Branch}:$ExpectedHead"
    $delete = Invoke-ReviewGit -Arguments @(
        '-C', $ConsumerRoot, 'push', $lease, 'origin',
        ":refs/heads/$Branch"
    ) -AllowedExitCodes @(0, 1)
    if ($delete.ExitCode -ne 0) {
        throw 'Capability-review branch expected-head lease rejected deletion.'
    }
    if ($null -ne (Invoke-ReviewGitHub -Method GET -Endpoint $endpoint `
        -AcceptNotFound)) {
        throw 'Capability-review branch remains after expected-head lease deletion.'
    }
}

function Close-VerifiedReviewIssue {
    param(
        [Parameter(Mandatory)]$Issue,
        [Parameter(Mandatory)]$Catalog,
        [Parameter(Mandatory)][string]$Marker,
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][long]$IssueNumber,
        [Parameter(Mandatory)][string]$ClosureMarker
    )

    Assert-LiveDefaultHeadUnchanged
    $escapedBranch = ConvertTo-GitRefEndpointPath -RefName $Branch
    $branchEndpoint = "repos/$Repository/git/ref/heads/$escapedBranch"
    if ($null -ne (Invoke-ReviewGitHub -Method GET `
        -Endpoint $branchEndpoint -AcceptNotFound)) {
        throw 'Capability review issue cannot close before branch deletion.'
    }
    $issueEndpoint = "repos/$Repository/issues/$IssueNumber"
    $rawIssue = Invoke-ReviewGitHub -Method GET -Endpoint $issueEndpoint `
        -Authority Issue
    $body = [string](Get-PropertyValue -Value $rawIssue -Name body `
        -Label 'Finalization issue')
    $state = [string](Get-PropertyValue -Value $rawIssue -Name state `
        -Label 'Finalization issue')
    $issueActor = Get-ActorRecord -User (
        Get-PropertyValue -Value $rawIssue -Name user `
            -Label 'Finalization issue'
    ) -Label 'Finalization issue actor'
    $issueBinding = Get-ReviewBinding -Body $body -Marker $Marker
    if ($state -cne 'open' -or -not (Test-IsIssueActor -Actor $issueActor) -or
        [long]$issueBinding.IssueActorId -ne [long]$issueActor.Id -or
        [string]$issueBinding.IssueActorLogin -cne [string]$issueActor.Login -or
        [long]$issueBinding.ProposalActorId -ne [long]$script:ProposalActor.Id -or
        [string]$issueBinding.ProposalActorLogin -cne
            [string]$script:ProposalActor.Login -or
        $body -cne [string]$Issue.Body) {
        throw 'Finalization issue authority drifted before closure.'
    }
    Assert-CanonicalReviewBody -Body $body -Binding $issueBinding `
        -Catalog $Catalog
    $existingClosure = Get-ClosureMarkerFromComments `
        -IssueNumber $IssueNumber -Repository $Repository `
        -CatalogDigest $Catalog.CatalogDigest
    if ([string]::IsNullOrEmpty($existingClosure)) {
        $closureBody = New-CanonicalClosureCommentBody -Marker $ClosureMarker
        $comment = Invoke-ReviewGitHub -Method POST `
            -Endpoint "$issueEndpoint/comments" -Body ([ordered]@{
                body = $closureBody
            }) -Authority Issue
        $commentActor = Get-ActorRecord -User (
            Get-PropertyValue -Value $comment -Name user `
                -Label 'Created capability review closure comment'
        ) -Label 'Created capability review closure comment actor'
        if (-not (Test-IsIssueActor -Actor $commentActor) -or
            [string]$comment.body -cne $closureBody) {
            throw 'Created capability review closure comment has untrusted authority.'
        }
    }
    elseif ($existingClosure -cne $ClosureMarker) {
        throw 'Finalization issue has conflicting closure evidence.'
    }
    $closedIssue = Invoke-ReviewGitHub -Method PATCH `
        -Endpoint $issueEndpoint -Body ([ordered]@{ state = 'closed' }) `
        -Authority Issue
    if ([string](Get-PropertyValue -Value $closedIssue -Name state `
        -Label 'Closed capability review issue') -cne 'closed') {
        throw 'Capability review issue did not reach closed state.'
    }
}

function Invoke-HistoricalCapabilityReviewRecovery {
    param([Parameter(Mandatory)]$Recovery)

    foreach ($operation in @($Recovery.Plan.Operations)) {
        if ([string]$operation.Kind -ceq 'DeleteBranch') {
            Remove-ReviewBranchWithLease -Branch ([string]$operation.Branch) `
                -ExpectedHead ([string]$operation.ExpectedHead)
        }
        elseif ([string]$operation.Kind -ceq 'CloseIssue') {
            Close-VerifiedReviewIssue -Issue $Recovery.Issue `
                -Catalog $Recovery.Catalog -Marker $Recovery.Plan.Marker `
                -Branch ([string]$Recovery.PullRequest.HeadBranch) `
                -IssueNumber ([long]$operation.IssueNumber) `
                -ClosureMarker ([string]$operation.ClosureMarker)
        }
        else {
            throw 'Historical capability-review recovery contains an unsupported operation.'
        }
    }
}

function New-Result {
    param(
        [Parameter(Mandatory)]$Plan,
        [AllowNull()]$Execution,
        [Parameter(Mandatory)]$Inventory,
        [string]$Mode
    )

    $catalogIdentity = if ($null -ne $Plan.PSObject.Properties['CatalogDigest']) {
        [string]$Plan.CatalogDigest
    } else {
        [string]$catalog.CatalogDigest
    }
    return [pscustomobject][ordered]@{
        Mode = $Mode
        State = [string]$Plan.State
        Plan = $Plan
        Execution = $Execution
        Repository = $Repository
        CatalogDigest = $catalogIdentity
        InventorySource = [string]$Inventory.Source
    }
}

$consumerFull = [IO.Path]::GetFullPath($ConsumerRoot)
$protocolFull = [IO.Path]::GetFullPath($ProtocolRoot)
$catalogModulePath = Join-Path $protocolFull 'scripts/MeAndAI.CapabilityCatalog.psm1'
$reviewModulePath = Join-Path $protocolFull 'scripts/MeAndAI.CapabilityReview.psm1'
$catalogIndexPath = Join-Path $protocolFull 'capabilities/index.json'
Assert-OrdinaryFile -LiteralPath $catalogModulePath `
    -Label 'Capability catalog module'
Assert-OrdinaryFile -LiteralPath $reviewModulePath `
    -Label 'Capability review module'
Assert-OrdinaryFile -LiteralPath $catalogIndexPath `
    -Label 'Capability catalog index'
Import-Module $catalogModulePath -Force
Import-Module $reviewModulePath -Force

if ([string]::IsNullOrWhiteSpace($Repository)) {
    throw 'Repository is required, normally from GITHUB_REPOSITORY.'
}
$Repository = $Repository.ToLowerInvariant()
if ([string]::IsNullOrWhiteSpace($DefaultBranch)) {
    throw 'DefaultBranch is required, normally from DEFAULT_BRANCH.'
}
if ([string]::IsNullOrWhiteSpace($TargetVersion)) {
    $versionPath = Join-Path $protocolFull 'VERSION'
    Assert-OrdinaryFile -LiteralPath $versionPath -Label 'Protocol VERSION'
    $versionText = [IO.File]::ReadAllText($versionPath).Trim()
    $TargetVersion = "v$versionText"
}

$catalog = Import-MeAndAICapabilityCatalog -IndexPath $catalogIndexPath
Assert-NoReparseBoundary -Root $consumerFull `
    -RelativePath $script:LedgerRelativePath `
    -Label 'Consumer capability ledger'
Assert-NoReparseBoundary -Root $consumerFull `
    -RelativePath $script:ManifestRelativePath `
    -Label 'Consumer capability review manifest'
$ledgerPath = Assert-ContainedPath -Root $consumerFull `
    -Path (Join-Path $consumerFull $script:LedgerRelativePath) `
    -Label 'Consumer capability ledger'
$checkoutEvidence = $null
if ($null -eq $FixtureInventory) {
    $checkoutEvidence = Assert-ProductionCheckout
    if (-not [string]::IsNullOrWhiteSpace($DefaultHead) -and
        $DefaultHead -cne [string]$checkoutEvidence.Head) {
        throw 'DefaultHead does not match the verified consumer checkout.'
    }
    $DefaultHead = [string]$checkoutEvidence.Head
}
else {
    $fixtureProposalActor = Get-PropertyValue -Value $FixtureInventory `
        -Name ProposalActor -Label 'Fixture inventory' -AllowMissing
    if ($null -eq $fixtureProposalActor) {
        $fixtureProposalActor = [pscustomobject][ordered]@{
            Id = 1
            Login = 'fixture-proposal'
        }
    }
    $fixtureIssueActor = Get-PropertyValue -Value $FixtureInventory `
        -Name IssueActor -Label 'Fixture inventory' -AllowMissing
    if ($null -eq $fixtureIssueActor) {
        $fixtureIssueActor = [pscustomobject][ordered]@{
            Id = 2
            Login = 'fixture-issue'
        }
    }
    $script:ProposalActor = [pscustomobject][ordered]@{
        Id = [long]$fixtureProposalActor.Id
        Login = [string]$fixtureProposalActor.Login
    }
    $script:IssueActor = [pscustomobject][ordered]@{
        Id = [long]$fixtureIssueActor.Id
        Login = [string]$fixtureIssueActor.Login
    }
}
$ledgerBytes = $null
if (Test-Path -LiteralPath $ledgerPath -PathType Leaf) {
    Assert-OrdinaryFile -LiteralPath $ledgerPath `
        -Label 'Consumer capability ledger'
    $ledgerBytes = [IO.File]::ReadAllBytes($ledgerPath)
}
$script:BaseLedgerDigest = if ($null -eq $ledgerBytes) {
    'missing'
} else {
    Get-Sha256Bytes -Bytes $ledgerBytes
}
$ledger = Import-MeAndAICapabilityLedger -Catalog $catalog -Bytes $ledgerBytes
$marker = Get-MeAndAICapabilityReviewMarker -Repository $Repository `
    -CatalogDigest $catalog.CatalogDigest
$expectedBranch = 'automation/meandai-capability-review-' +
    $catalog.CatalogDigest.Substring(0, 16)

if ($null -ne $FixtureInventory) {
    if (-not $PlanOnly) {
        throw 'FixtureInventory is allowed only with PlanOnly.'
    }
    if ([string]::IsNullOrWhiteSpace($DefaultHead)) {
        $DefaultHead = [string](Get-PropertyValue -Value $FixtureInventory `
            -Name CurrentDefaultHead -Label 'Fixture inventory')
    }
    Assert-GitSha -Value $DefaultHead -Label 'Fixture default head'
    $fixtureIssues = Get-PropertyValue -Value $FixtureInventory -Name Issues `
        -Label 'Fixture inventory' -AllowMissing
    $fixtureBranches = Get-PropertyValue -Value $FixtureInventory -Name Branches `
        -Label 'Fixture inventory' -AllowMissing
    $fixturePulls = Get-PropertyValue -Value $FixtureInventory `
        -Name PullRequests -Label 'Fixture inventory' -AllowMissing
    $fixtureManifests = Get-PropertyValue -Value $FixtureInventory `
        -Name Manifests -Label 'Fixture inventory' -AllowMissing
    $inventory = [pscustomobject][ordered]@{
        Issues = if ($null -eq $fixtureIssues) { @() } else { @($fixtureIssues) }
        Branches = if ($null -eq $fixtureBranches) { @() } else { @($fixtureBranches) }
        PullRequests = if ($null -eq $fixturePulls) { @() } else { @($fixturePulls) }
        Manifests = if ($null -eq $fixtureManifests) { @() } else { @($fixtureManifests) }
        Binding = Get-PropertyValue -Value $FixtureInventory -Name Binding `
            -Label 'Fixture inventory' -AllowMissing
        ReviewBaseHead = [string](Get-PropertyValue -Value $FixtureInventory `
            -Name ReviewBaseHead -Label 'Fixture inventory' -AllowMissing)
        CurrentDefaultHead = $DefaultHead
        HistoricalIssues = @()
        Source = 'Fixture'
        DefaultContainsMerge = [bool](Get-PropertyValue `
            -Value $FixtureInventory -Name DefaultContainsMerge `
            -Label 'Fixture inventory' -AllowMissing)
        ManifestPresentOnDefault = [bool](Get-PropertyValue `
            -Value $FixtureInventory -Name ManifestPresentOnDefault `
            -Label 'Fixture inventory' -AllowMissing)
        Reviewed = [bool](Get-PropertyValue -Value $FixtureInventory `
            -Name Reviewed -Label 'Fixture inventory' -AllowMissing)
    }
    if ([string]::IsNullOrWhiteSpace($inventory.ReviewBaseHead)) {
        $inventory.ReviewBaseHead = $DefaultHead
    }
}
else {
    $inventory = Get-ProductionInventory -Catalog $catalog -Marker $marker `
        -ExpectedBranch $expectedBranch -CurrentDefaultHead $DefaultHead
    if ($inventory.ReviewBaseHead -cne $DefaultHead -and
        -not (Test-LocalAncestor -Ancestor $inventory.ReviewBaseHead `
            -Descendant $DefaultHead)) {
        throw 'Capability review base is not contained by the current default branch.'
    }
    $historicalIssues = @($inventory.HistoricalIssues)
    if ($historicalIssues.Count -eq 0 -and
        $FinalizePullRequestNumber -gt 0) {
        $currentPulls = @($inventory.PullRequests)
        if ($currentPulls.Count -ne 1 -or
            [long]$currentPulls[0].Number -ne $FinalizePullRequestNumber) {
            throw 'The requested finalization pull request is not the exact canonical review.'
        }
    }
    if ($historicalIssues.Count -gt 0) {
        if ($historicalIssues.Count -ne 1) {
            throw 'Historical capability-review recovery is not uniquely bounded.'
        }
        if ($null -eq $ledgerBytes) {
            throw 'Historical capability-review recovery requires the committed capability ledger.'
        }
        $historicalRecovery = Resolve-HistoricalCapabilityReviewRecovery `
            -HistoricalIssue $historicalIssues[0] `
            -CurrentCatalog $catalog -CurrentLedger $ledger `
            -CurrentLedgerBytes ([byte[]]$ledgerBytes) `
            -CurrentDefaultHead $DefaultHead
        if ($PlanOnly) {
            return New-Result -Plan $historicalRecovery.Plan -Execution $null `
                -Inventory $inventory -Mode 'PlanOnly'
        }
        Invoke-HistoricalCapabilityReviewRecovery -Recovery $historicalRecovery
        $inventory = Get-ProductionInventory -Catalog $catalog -Marker $marker `
            -ExpectedBranch $expectedBranch -CurrentDefaultHead $DefaultHead
        if (@($inventory.HistoricalIssues).Count -ne 0) {
            throw 'Historical capability-review recovery did not converge to one fresh current inventory.'
        }
        if ($inventory.ReviewBaseHead -cne $DefaultHead -and
            -not (Test-LocalAncestor -Ancestor $inventory.ReviewBaseHead `
                -Descendant $DefaultHead)) {
            throw 'Capability review base is not contained by the current default branch.'
        }
    }
}
if ($null -ne $inventory.Binding -and
    $null -ne $inventory.Binding.PSObject.Properties['BaseLedgerDigest']) {
    $script:BaseLedgerDigest = [string]$inventory.Binding.BaseLedgerDigest
}

$reviewBaseHead = [string]$inventory.ReviewBaseHead
Assert-GitSha -Value $reviewBaseHead -Label 'Capability review base head'
$mergedPulls = @($inventory.PullRequests | Where-Object {
    [string]$_.State -ceq 'Merged'
})
$closedUnmerged = @($inventory.PullRequests | Where-Object {
    [string]$_.State -ceq 'Closed'
})
if ($closedUnmerged.Count -gt 0) {
    throw 'The canonical capability-review pull request closed without merge.'
}
$ledgerComplete = @($ledger.Entries).Count -eq @($catalog.Capabilities).Count

if ($mergedPulls.Count -gt 0) {
    if ($mergedPulls.Count -ne 1 -or -not $ledgerComplete) {
        throw 'Merged capability review lacks one complete target-catalog ledger.'
    }
    if (@($inventory.Issues).Count -ne 1) {
        throw 'Merged capability review lacks one canonical tracking issue.'
    }
    $pullRequest = $mergedPulls[0]
    $issue = $inventory.Issues[0]
    $binding = Get-PropertyValue -Value $pullRequest -Name Binding `
        -Label 'Merged capability review pull request' -AllowMissing
    if ($null -eq $binding) {
        $binding = $inventory.Binding
    }
    if ($null -eq $binding) {
        throw 'Merged capability review lacks its immutable binding.'
    }
    $verifiedReviewer = $null
    if ($FixtureInventory) {
        if (-not $inventory.Reviewed) {
            throw 'Fixture merged review is not marked reviewed.'
        }
    }
    else {
        $verifiedReviewer = Assert-MergedReview -PullRequest $pullRequest `
            -Ledger $ledger `
            -LedgerPrefixCount ([int]$binding.LedgerPrefixCount)
        Assert-MergedTreeEvidence -PullRequest $pullRequest -Binding $binding `
            -Catalog $catalog -Ledger $ledger `
            -CurrentLedgerBytes ([byte[]]$ledgerBytes) -Marker $marker `
            -CurrentDefaultHead $DefaultHead
    }
    $defaultContainsMerge = if ($FixtureInventory) {
        [bool]$inventory.DefaultContainsMerge
    } else {
        Test-LocalAncestor -Ancestor ([string]$pullRequest.MergeCommit) `
            -Descendant $DefaultHead
    }
    $manifestOnDefault = if ($FixtureInventory) {
        [bool]$inventory.ManifestPresentOnDefault
    } else {
        Test-Path -LiteralPath (
            Join-Path $consumerFull $script:ManifestRelativePath
        )
    }
    $branch = if (@($inventory.Branches).Count -eq 1) {
        $inventory.Branches[0]
    } else {
        $null
    }
    $plan = Resolve-MeAndAICapabilityReviewFinalization `
        -Catalog $catalog -Ledger $ledger -Repository $Repository `
        -DefaultBranch $DefaultBranch -Marker $marker `
        -ExpectedBranch $expectedBranch `
        -ExpectedBaseHead ([string]$binding.BaseHead) `
        -ExpectedReviewHead ([string]$pullRequest.HeadSha) `
        -Issue $issue -Branch $branch -PullRequest $pullRequest `
        -DefaultContainsMerge:$defaultContainsMerge `
        -ManifestPresentOnDefault:$manifestOnDefault
    if ($null -ne $verifiedReviewer) {
        $plan | Add-Member -NotePropertyName VerifiedReviewer `
            -NotePropertyValue $verifiedReviewer -Force
    }
}
else {
    $plan = Resolve-MeAndAICapabilityReview -Catalog $catalog -Ledger $ledger `
        -Repository $Repository -DefaultBranch $DefaultBranch `
        -DefaultHead $reviewBaseHead -TargetVersion $TargetVersion `
        -DiscoveryContext $DiscoveryContext -SourceVersion $SourceVersion `
        -FrameworkInstalled:$FrameworkInstalled -Assessments $Assessments `
        -ExistingIssues @($inventory.Issues) `
        -ExistingBranches @($inventory.Branches) `
        -ExistingPullRequests @($inventory.PullRequests) `
        -ExistingManifests @($inventory.Manifests)
    if ($plan.PSObject.Properties['BatchDigest']) {
        $ledgerPrefixCount = @($ledger.Entries).Count
        Assert-BindingMatchesPlan -Binding $inventory.Binding -Plan $plan `
            -LedgerPrefixCount $ledgerPrefixCount
        foreach ($manifest in @($inventory.Manifests)) {
            Assert-BindingMatchesPlan -Binding $manifest -Plan $plan `
                -LedgerPrefixCount $ledgerPrefixCount `
                -Label 'Capability review manifest'
            Assert-CanonicalManifest -Manifest $manifest -Plan $plan `
                -Catalog $catalog -LedgerPrefixCount $ledgerPrefixCount
        }
    }
}

if ($PlanOnly -or @($plan.Operations).Count -eq 0 -or
    [string]$plan.State -ceq 'ProtocolUpdateRequired') {
    return New-Result -Plan $plan -Execution $null -Inventory $inventory `
        -Mode 'PlanOnly'
}

$executionState = [ordered]@{
    Issue = if (@($inventory.Issues).Count -eq 1) {
        $inventory.Issues[0]
    } else {
        $null
    }
    Branch = if (@($inventory.Branches).Count -eq 1) {
        $inventory.Branches[0]
    } else {
        $null
    }
    PullRequest = if (@($inventory.PullRequests).Count -eq 1) {
        $inventory.PullRequests[0]
    } else {
        $null
    }
}

$handlers = @{
    CreateBranch = {
        param($Operation, $ReviewPlan)
        $escapedBranch = ConvertTo-GitRefEndpointPath `
            -RefName ([string]$ReviewPlan.Branch)
        $response = Invoke-ReviewGitHub -Method POST `
            -Endpoint "repos/$Repository/git/refs" -Body ([ordered]@{
                ref = "refs/heads/$($ReviewPlan.Branch)"
                sha = [string]$ReviewPlan.BaseHead
            })
        $createdRef = [string](Get-PropertyValue -Value $response -Name ref `
            -Label 'Created capability review branch')
        $object = Get-PropertyValue -Value $response -Name object `
            -Label 'Created capability review branch'
        [void](Get-PropertyValue -Value $object -Name sha `
            -Label 'Created capability review branch')
        if ($createdRef -cne "refs/heads/$($ReviewPlan.Branch)") {
            throw 'Created capability-review branch has unexpected head.'
        }
        $createdBranch = Invoke-ReviewGitHub -Method GET `
            -Endpoint "repos/$Repository/git/ref/heads/$escapedBranch"
        $createdObject = Get-PropertyValue -Value $createdBranch -Name object `
            -Label 'Created capability review branch ref'
        $head = [string](Get-PropertyValue -Value $createdObject -Name sha `
            -Label 'Created capability review branch ref')
        if ($head -cne [string]$ReviewPlan.BaseHead) {
            throw 'Created capability-review branch has unexpected head.'
        }
        $executionState.Branch = [pscustomobject][ordered]@{
            Name = [string]$ReviewPlan.Branch
            BaseHead = [string]$ReviewPlan.BaseHead
            HeadSha = $head
            Marker = [string]$ReviewPlan.Marker
        }
    }
    OpenIssue = {
        param($Operation, $ReviewPlan)
        if ($null -eq $executionState.Branch) {
            throw 'Capability review issue cannot precede branch creation.'
        }
        $body = New-ReviewBody -Plan $ReviewPlan `
            -LedgerPrefixCount @($ledger.Entries).Count
        $response = Invoke-ReviewGitHub -Method POST `
            -Endpoint "repos/$Repository/issues" -Body ([ordered]@{
                title = "[meAndAI] Review capability catalog $($ReviewPlan.CatalogDigest.Substring(0, 12))"
                body = $body
            }) -Authority Issue
        $number = [long](Get-PropertyValue -Value $response -Name number `
            -Label 'Created capability review issue')
        $createdBody = [string](Get-PropertyValue -Value $response -Name body `
            -Label 'Created capability review issue')
        $createdActor = Get-ActorRecord -User (
            Get-PropertyValue -Value $response -Name user `
                -Label 'Created capability review issue'
        ) -Label 'Created capability review issue actor'
        if ($number -le 0 -or $createdBody -cne $body -or
            -not (Test-IsIssueActor -Actor $createdActor)) {
            throw 'Created capability review issue is not the exact issue-authority artifact.'
        }
        $executionState.Issue = [pscustomobject][ordered]@{
            Number = $number
            State = 'Open'
            Marker = [string]$ReviewPlan.Marker
        }
    }
    WriteReviewManifest = {
        param($Operation, $ReviewPlan)
        if ($null -eq $executionState.Issue -or
            $null -eq $executionState.Branch) {
            throw 'Capability review manifest requires branch and issue identity.'
        }
        $escapedBranch = ConvertTo-GitRefEndpointPath `
            -RefName ([string]$ReviewPlan.Branch)
        $manifestBytes = New-ManifestBytes -Plan $ReviewPlan `
            -IssueNumber ([long]$executionState.Issue.Number) `
            -LedgerPrefixCount @($ledger.Entries).Count
        $blob = Invoke-ReviewGitHub -Method POST `
            -Endpoint "repos/$Repository/git/blobs" -Body ([ordered]@{
                content = [Convert]::ToBase64String($manifestBytes)
                encoding = 'base64'
            })
        $blobSha = [string](Get-PropertyValue -Value $blob -Name sha `
            -Label 'Capability review manifest blob')
        Assert-GitSha -Value $blobSha -Label 'Capability review manifest blob'

        $parentHead = [string]$executionState.Branch.HeadSha
        $parentCommit = Invoke-ReviewGitHub -Method GET `
            -Endpoint "repos/$Repository/git/commits/$parentHead"
        $parentTree = Get-PropertyValue -Value $parentCommit -Name tree `
            -Label 'Capability review parent commit'
        $parentTreeSha = [string](Get-PropertyValue -Value $parentTree `
            -Name sha -Label 'Capability review parent tree')
        Assert-GitSha -Value $parentTreeSha -Label 'Capability review parent tree'
        $tree = Invoke-ReviewGitHub -Method POST `
            -Endpoint "repos/$Repository/git/trees" -Body ([ordered]@{
                base_tree = $parentTreeSha
                tree = @(
                    [ordered]@{
                        path = $script:ManifestRelativePath
                        mode = '100644'
                        type = 'blob'
                        sha = $blobSha
                    }
                )
            })
        $treeSha = [string](Get-PropertyValue -Value $tree -Name sha `
            -Label 'Capability review manifest tree')
        Assert-GitSha -Value $treeSha -Label 'Capability review manifest tree'
        $commit = Invoke-ReviewGitHub -Method POST `
            -Endpoint "repos/$Repository/git/commits" -Body ([ordered]@{
                message = 'chore(ai): open capability review handoff'
                tree = $treeSha
                parents = @($parentHead)
            })
        $commitSha = [string](Get-PropertyValue -Value $commit -Name sha `
            -Label 'Capability review manifest commit')
        Assert-GitSha -Value $commitSha -Label 'Capability review manifest commit'
        $parents = @((Get-PropertyValue -Value $commit -Name parents `
            -Label 'Capability review manifest commit'))
        if ($parents.Count -ne 1 -or [string]$parents[0].sha -cne $parentHead) {
            throw 'Capability review manifest commit has unexpected parent.'
        }
        [void](Invoke-ReviewGitHub -Method PATCH `
            -Endpoint "repos/$Repository/git/refs/heads/$escapedBranch" `
            -Body ([ordered]@{ sha = $commitSha; force = $false }))
        $compare = Invoke-ReviewGitHub -Method GET `
            -Endpoint "repos/$Repository/compare/$parentHead...$commitSha"
        $files = @((Get-PropertyValue -Value $compare -Name files `
            -Label 'Capability review manifest comparison'))
        if ($files.Count -ne 1 -or
            [string]$files[0].filename -cne $script:ManifestRelativePath) {
            throw 'Capability review commit changed a path other than its transient manifest.'
        }
        $executionState.Branch.HeadSha = $commitSha
    }
    OpenDraftPullRequest = {
        param($Operation, $ReviewPlan)
        if ($null -eq $executionState.Issue -or
            $null -eq $executionState.Branch) {
            throw 'Capability review pull request requires branch and issue identity.'
        }
        $body = New-ReviewBody -Plan $ReviewPlan `
            -LedgerPrefixCount @($ledger.Entries).Count `
            -IssueNumber ([int]$executionState.Issue.Number) `
            -HandoffHead ([string]$executionState.Branch.HeadSha)
        $response = Invoke-ReviewGitHub -Method POST `
            -Endpoint "repos/$Repository/pulls" -Body ([ordered]@{
                title = "chore(ai): review capability catalog $($ReviewPlan.CatalogDigest.Substring(0, 12))"
                head = [string]$ReviewPlan.Branch
                base = [string]$ReviewPlan.BaseBranch
                body = $body
                draft = $true
            })
        $number = [long](Get-PropertyValue -Value $response -Name number `
            -Label 'Created capability review pull request')
        $draft = [bool](Get-PropertyValue -Value $response -Name draft `
            -Label 'Created capability review pull request')
        $head = Get-PropertyValue -Value $response -Name head `
            -Label 'Created capability review pull request'
        $headSha = [string](Get-PropertyValue -Value $head -Name sha `
            -Label 'Created capability review pull request head')
        $headRef = [string](Get-PropertyValue -Value $head -Name ref `
            -Label 'Created capability review pull request head')
        $headRepository = Get-PropertyValue -Value $head -Name repo `
            -Label 'Created capability review pull request head'
        $headRepositoryName = [string](Get-PropertyValue `
            -Value $headRepository -Name full_name `
            -Label 'Created capability review pull request head repository')
        $createdBody = [string](Get-PropertyValue -Value $response -Name body `
            -Label 'Created capability review pull request')
        $createdActor = Get-ActorRecord -User (
            Get-PropertyValue -Value $response -Name user `
                -Label 'Created capability review pull request'
        ) -Label 'Created capability review pull request actor'
        $createdBase = Get-PropertyValue -Value $response -Name base `
            -Label 'Created capability review pull request'
        $baseRef = [string](Get-PropertyValue -Value $createdBase -Name ref `
            -Label 'Created capability review pull request base')
        if ($number -le 0 -or -not $draft -or
            $headSha -cne [string]$executionState.Branch.HeadSha -or
            $headRef -cne [string]$ReviewPlan.Branch -or
            $headRepositoryName.ToLowerInvariant() -cne $Repository -or
            $baseRef -cne [string]$ReviewPlan.BaseBranch -or
            $createdBody -cne $body -or
            -not (Test-IsProposalActor -Actor $createdActor)) {
            throw 'Created capability review pull request is not the exact draft.'
        }
        $executionState.PullRequest = [pscustomobject][ordered]@{
            Number = $number
            State = 'Open'
            IsDraft = $true
            HeadSha = $headSha
        }
    }
    AppendTerminalLedger = {
        param($Operation, $ReviewPlan)
        $assessmentBySlug = @{}
        foreach ($assessment in @($Assessments)) {
            $slug = [string](Get-PropertyValue -Value $assessment -Name Slug `
                -Label 'Terminal capability assessment')
            if ($assessmentBySlug.ContainsKey($slug)) {
                throw "Terminal capability assessment '$slug' is duplicated."
            }
            $assessmentBySlug.Add($slug, $assessment)
        }
        $newEntries = [System.Collections.Generic.List[object]]::new()
        foreach ($entry in @($Operation.Entries)) {
            $assessment = $assessmentBySlug[[string]$entry.Slug]
            if ($null -eq $assessment) {
                throw "Terminal capability assessment '$($entry.Slug)' is absent."
            }
            $authority = [string](Get-PropertyValue -Value $assessment `
                -Name ReviewAuthority -Label 'Terminal capability assessment')
            $reviewedAt = [string](Get-PropertyValue -Value $assessment `
                -Name ReviewedAt -Label 'Terminal capability assessment')
            $capability = @($catalog.Capabilities | Where-Object {
                [string]$_.Slug -ceq [string]$entry.Slug
            })
            if ($capability.Count -ne 1) {
                throw 'Terminal capability assessment does not bind one catalog entry.'
            }
            $newEntries.Add((New-MeAndAICapabilityLedgerEntry `
                -Capability $capability[0] -Outcome ([string]$entry.Outcome) `
                -Evidence @($entry.Evidence) `
                -ReviewIdentity ([string]$entry.ReviewIdentity) `
                -ReviewAuthority $authority -ReviewedAt $reviewedAt))
        }
        $bytes = ConvertTo-MeAndAICapabilityLedgerBytes -Catalog $catalog `
            -Entries @(@($ledger.Entries) + @($newEntries))
        $parent = Split-Path -Parent $ledgerPath
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            [void](New-Item -ItemType Directory -Path $parent -Force)
        }
        [IO.File]::WriteAllBytes($ledgerPath, $bytes)
        [void](Import-MeAndAICapabilityLedger -Catalog $catalog `
            -Bytes ([IO.File]::ReadAllBytes($ledgerPath)))
    }
    DeleteBranch = {
        param($Operation, $ReviewPlan)
        Remove-ReviewBranchWithLease -Branch ([string]$Operation.Branch) `
            -ExpectedHead ([string]$Operation.ExpectedHead)
    }
    CloseIssue = {
        param($Operation, $ReviewPlan)
        Close-VerifiedReviewIssue -Issue $executionState.Issue `
            -Catalog $catalog -Marker ([string]$Operation.Marker) `
            -Branch $expectedBranch `
            -IssueNumber ([long]$Operation.IssueNumber) `
            -ClosureMarker ([string]$Operation.ClosureMarker)
    }
}

$execution = Invoke-MeAndAICapabilityReviewPlan -Plan $plan `
    -Handlers $handlers
return New-Result -Plan $plan -Execution $execution -Inventory $inventory `
    -Mode 'Execute'
