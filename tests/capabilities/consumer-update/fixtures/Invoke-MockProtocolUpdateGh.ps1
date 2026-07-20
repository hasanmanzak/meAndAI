[CmdletBinding()]
param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$mode = [string]$env:MEANDAI_TEST_GH_MODE
$failureKind = [string]$env:MEANDAI_TEST_GH_FAILURE_KIND
$failuresBeforeSuccess = if ([string]::IsNullOrWhiteSpace(
        [string]$env:MEANDAI_TEST_GH_FAILURES)) {
    0
}
else { [int]$env:MEANDAI_TEST_GH_FAILURES }
$statePath = [string]$env:MEANDAI_TEST_GH_STATE
$logPath = [string]$env:MEANDAI_TEST_GH_LOG

if ([string]::IsNullOrWhiteSpace($statePath) -or
    [string]::IsNullOrWhiteSpace($logPath)) {
    [Console]::Error.WriteLine('Mock GitHub CLI requires state and log paths.')
    exit 90
}

$attempt = if (Test-Path -LiteralPath $statePath -PathType Leaf) {
    [int]([IO.File]::ReadAllText($statePath).Trim()) + 1
}
else { 1 }
[IO.File]::WriteAllText(
    $statePath, [string]$attempt, [Text.UTF8Encoding]::new($false)
)

$bodyPath = ''
$bodyMode = ''
for ($index = 0; $index -lt $Arguments.Count; $index++) {
    $argument = [string]$Arguments[$index]
    if ($argument.StartsWith('body=@', [StringComparison]::Ordinal)) {
        $bodyPath = $argument.Substring('body=@'.Length)
        $bodyMode = if ($index -gt 0 -and
            [string]$Arguments[$index - 1] -cin @('-F', '--field')) {
            'RestField'
        }
        else { 'InvalidRestField' }
        break
    }
    if ($argument -ceq '--body-file' -and $index + 1 -lt $Arguments.Count) {
        $bodyPath = [string]$Arguments[$index + 1]
        $bodyMode = 'PullRequestBodyFile'
        break
    }
}

$bodyBytes = [byte[]]@()
if ($bodyPath) {
    if (-not (Test-Path -LiteralPath $bodyPath -PathType Leaf)) {
        [Console]::Error.WriteLine("Body transport file is missing: $bodyPath")
        exit 91
    }
    $bodyBytes = [IO.File]::ReadAllBytes($bodyPath)
}
$hasBom = $bodyBytes.Length -ge 3 -and
    $bodyBytes[0] -eq 0xEF -and $bodyBytes[1] -eq 0xBB -and
    $bodyBytes[2] -eq 0xBF
$record = [ordered]@{
    attempt = $attempt
    utcTicks = [DateTime]::UtcNow.Ticks
    arguments = @($Arguments)
    bodyPath = $bodyPath
    bodyMode = $bodyMode
    bodyBase64 = if ($bodyBytes.Length -eq 0) {
        ''
    }
    else { [Convert]::ToBase64String($bodyBytes) }
    bodyHasBom = [bool]$hasBom
}
[IO.File]::AppendAllText(
    $logPath,
    (($record | ConvertTo-Json -Depth 5 -Compress) + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false)
)
if ($bodyMode -ceq 'InvalidRestField') {
    [Console]::Error.WriteLine(
        'REST @file body transport requires the typed -F/--field flag.'
    )
    exit 93
}

function Test-ExactReadArguments {
    param([Parameter(Mandatory)][string[]]$Value)

    if ($Value.Count -lt 2 -or $Value[0] -cne 'api') { return $false }
    $endpointCount = 0
    for ($index = 1; $index -lt $Value.Count; $index++) {
        $argument = [string]$Value[$index]
        if ($argument -cin @('--method', '-X')) {
            if ($index + 1 -ge $Value.Count -or
                [string]$Value[++$index] -cne 'GET') {
                return $false
            }
            continue
        }
        if ($argument -cin @('-H', '--header')) {
            if ($index + 1 -ge $Value.Count -or
                [string]::IsNullOrWhiteSpace([string]$Value[++$index])) {
                return $false
            }
            continue
        }
        if ($argument -ceq '--paginate') { continue }
        if ($argument -ceq '--jq') {
            if ($index + 1 -ge $Value.Count -or
                [string]$Value[++$index] -cne '.[] | @base64') {
                return $false
            }
            continue
        }
        if ($argument.StartsWith('-', [StringComparison]::Ordinal) -or
            [string]::IsNullOrWhiteSpace($argument)) {
            return $false
        }
        $endpointCount++
    }
    return $endpointCount -eq 1
}

if ($mode -cin @('Read', 'Paged') -and
    -not (Test-ExactReadArguments -Value $Arguments)) {
    [Console]::Error.WriteLine(
        'Read mode received arguments outside the exact GET-only allowlist.'
    )
    exit 94
}

function Write-MockFailure {
    param([Parameter(Mandatory)][string]$Kind)

    $message = switch ($Kind) {
        'Connectex' {
            'Get "https://api.github.com/repos/owner/consumer": connectex: A connection attempt failed because the connected party did not properly respond'
        }
        'Timeout' {
            'Get "https://api.github.com/repos/owner/consumer": context deadline exceeded (Client.Timeout exceeded while awaiting headers)'
        }
        'Reset' {
            'read tcp 127.0.0.1:443: wsarecv: An existing connection was forcibly closed by the remote host'
        }
        'Eof' { 'Get "https://api.github.com/repos/owner/consumer": unexpected EOF' }
        '408' { 'gh: Request timeout (HTTP 408)' }
        '429' { 'gh: API rate limit exceeded (HTTP 429)' }
        '500' { 'gh: Internal Server Error (HTTP 500)' }
        '502' { 'gh: Bad Gateway (HTTP 502)' }
        '503' { 'gh: Service Unavailable (HTTP 503)' }
        '599' { 'gh: Network Connect Timeout Error (HTTP 599)' }
        '401' { 'gh: Requires authentication (HTTP 401)' }
        '403' { 'gh: Resource not accessible (HTTP 403)' }
        '404' { 'gh: Not Found (HTTP 404)' }
        '422' { 'gh: Validation Failed (HTTP 422)' }
        default { "gh: permanent native failure '$Kind'" }
    }
    [Console]::Error.WriteLine($message)
    exit 1
}

if ($mode -ceq 'InvalidJson') {
    '{not-json'
    exit 0
}

if ($mode -ceq 'Read' -or $mode -ceq 'Paged') {
    if ($attempt -le $failuresBeforeSuccess) {
        if ($mode -ceq 'Paged') {
            $partial = [Text.Encoding]::UTF8.GetBytes('{"id":999}')
            [Convert]::ToBase64String($partial)
        }
        Write-MockFailure -Kind $failureKind
    }
    if ($mode -ceq 'Paged') {
        foreach ($json in @('{"id":1}', '{"id":2}')) {
            [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))
        }
    }
    else {
        [ordered]@{ attempt = $attempt; value = 'ok' } |
            ConvertTo-Json -Compress
    }
    exit 0
}

if ($mode -ceq 'MutationFailure') {
    Write-MockFailure -Kind 'PermanentMutation'
}
if ($mode -ceq 'Mutation') {
    [ordered]@{ ok = $true; attempt = $attempt } | ConvertTo-Json -Compress
    exit 0
}
if ($mode -ceq 'PullRequest') {
    'https://github.com/owner/consumer/pull/123'
    exit 0
}
if ($mode -ceq 'PullRequestFailure') {
    Write-MockFailure -Kind 'PermanentPullRequest'
}

[Console]::Error.WriteLine(
    "Unexpected mock GitHub CLI mode '$mode' for: $($Arguments -join ' ')"
)
exit 92
