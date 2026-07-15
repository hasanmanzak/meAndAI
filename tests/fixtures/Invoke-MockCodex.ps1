[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'
$stdin = [Console]::In.ReadToEnd()
$logPath = [Environment]::GetEnvironmentVariable('MEANDAI_TEST_CODEX_LOG')
if ([string]::IsNullOrWhiteSpace($logPath)) {
    throw 'MEANDAI_TEST_CODEX_LOG is required.'
}
$record = [ordered]@{
    Arguments = @($Arguments)
    Stdin = $stdin
} | ConvertTo-Json -Compress -Depth 5
Add-Content -LiteralPath $logPath -Value $record -Encoding UTF8

$mode = [Environment]::GetEnvironmentVariable('MEANDAI_TEST_CODEX_MODE')
if (-not $mode) {
    $mode = 'Success'
}
if (($Arguments -join ' ') -eq 'login status') {
    if ($mode -ceq 'Unauthenticated') {
        [Console]::Error.WriteLine('Not logged in')
        exit 1
    }
    [Console]::Out.WriteLine('Logged in using test authentication')
    exit 0
}
if ($Arguments.Count -eq 0 -or $Arguments[0] -cne 'exec') {
    throw "Unexpected mock Codex call: $($Arguments -join ' ')"
}

$workingIndex = [Array]::IndexOf([object[]]$Arguments, '--cd')
$outputIndex = [Array]::IndexOf([object[]]$Arguments, '--output-last-message')
if ($workingIndex -lt 0 -or $workingIndex + 1 -ge $Arguments.Count -or
    $outputIndex -lt 0 -or $outputIndex + 1 -ge $Arguments.Count) {
    throw 'Mock Codex did not receive isolated working and output paths.'
}
$working = $Arguments[$workingIndex + 1]
$output = $Arguments[$outputIndex + 1]
$target = [Environment]::GetEnvironmentVariable('MEANDAI_TEST_CODEX_TARGET')
if ($working -ceq $target -or
    (Test-Path -LiteralPath (Join-Path $working 'FG_PAT.txt')) -or
    (Test-Path -LiteralPath (Join-Path $working 'MEANDAI_RO_FG_PAT.txt'))) {
    throw 'Mock Codex was exposed to the consumer credential workspace.'
}
if ($stdin.Contains('write-token-value') -or $stdin.Contains('read-token-value')) {
    throw 'Mock Codex prompt contains a credential value.'
}
$argumentText = $Arguments -join "`n"
$networkIndex = [Array]::IndexOf([object[]]$Arguments, 'sandbox_workspace_write.network_access')
$networkDisabled = $argumentText.Contains('sandbox_workspace_write.network_access=false') -or
    ($networkIndex -ge 0 -and $networkIndex + 1 -lt $Arguments.Count -and
        $Arguments[$networkIndex + 1] -ceq 'false')
$networkEnabled = $argumentText.Contains('sandbox_workspace_write.network_access=true') -or
    ($networkIndex -ge 0 -and $networkIndex + 1 -lt $Arguments.Count -and
        $Arguments[$networkIndex + 1] -ceq 'true')
if (-not $networkDisabled -or $networkEnabled -or
    $stdin.Contains('Use gh only') -or $stdin.Contains('Use gh for')) {
    throw "Mock Codex did not receive the enforced network-free publication boundary (disabled=$networkDisabled; enabled=$networkEnabled; arguments=$($Arguments -join '|'))."
}

$manifestPath = Join-Path $working '.ai/adoption/meandai-capabilities.json'
$manifest = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
$protocolEntry = (& git -C $working ls-files --stage -- .ai/protocol 2>&1) -join ''
if (-not $protocolEntry) {
    $gitmodules = @(
        '[submodule ".ai/protocol"]',
        "`tpath = .ai/protocol",
        "`turl = https://github.com/hasanmanzak/meAndAI.git",
        ''
    ) -join "`n"
    [IO.File]::WriteAllText(
        (Join-Path $working '.gitmodules'),
        $gitmodules,
        [Text.UTF8Encoding]::new($false)
    )
    & git -C $working update-index --add --cacheinfo "160000,$([string]$manifest.protocolSha),.ai/protocol"
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to stage the mock protocol gitlink.'
    }
}
$evidencePath = Join-Path $working 'docs/ai-adoption.md'
New-Item -ItemType Directory -Path (Split-Path -Parent $evidencePath) -Force | Out-Null
Set-Content -LiteralPath $evidencePath -Value '# Local adoption evidence' -Encoding UTF8
if ($mode -ceq 'RenameWorkflowAway') {
    $workflowPath = Join-Path $working '.github/workflows/meandai-protocol-update.yml'
    $renamedPath = Join-Path $working '.github/workflows/meandai-protocol-update-renamed.yml'
    & git -C $working mv -- $workflowPath $renamedPath
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to rename the protected mock lifecycle workflow.'
    }
}
if ($mode -cne 'LeaveManifest') {
    Remove-Item -LiteralPath $manifestPath -Force
}
if ($mode -ceq 'CreateCommit') {
    & git -C $working config user.name 'meAndAI Test'
    & git -C $working config user.email 'meandai-test@example.invalid'
    & git -C $working config commit.gpgsign false
    & git -C $working add -A
    & git -C $working commit -m 'Unexpected Codex commit'
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to create the unexpected mock Codex commit.'
    }
}
if ($mode -ceq 'RemoteRace') {
    $remote = [Environment]::GetEnvironmentVariable('MEANDAI_TEST_CODEX_REMOTE')
    $raceRoot = Join-Path ([IO.Path]::GetTempPath()) "meandai-mock-race-$([guid]::NewGuid().ToString('N'))"
    $raceClone = Join-Path $raceRoot 'clone'
    try {
        New-Item -ItemType Directory -Path $raceRoot -Force | Out-Null
        & git clone --branch 'automation/meandai-capabilities-v0.8.1' $remote $raceClone
        if ($LASTEXITCODE -ne 0) { throw 'Unable to create mock race clone.' }
        & git -C $raceClone config user.name 'meAndAI Test'
        & git -C $raceClone config user.email 'meandai-test@example.invalid'
        & git -C $raceClone config commit.gpgsign false
        Set-Content -LiteralPath (Join-Path $raceClone 'concurrent.txt') -Value 'race' -Encoding UTF8
        & git -C $raceClone add concurrent.txt
        & git -C $raceClone commit -m 'Concurrent adoption change'
        & git -C $raceClone push origin HEAD
        if ($LASTEXITCODE -ne 0) { throw 'Unable to publish mock race change.' }
    }
    finally {
        if (Test-Path -LiteralPath $raceRoot) {
            Remove-Item -LiteralPath $raceRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
if ($mode -ceq 'Sleep') {
    Start-Sleep -Seconds 120
}

[IO.File]::WriteAllText(
    $output,
    'MEANDAI_ADOPTION_READY - mock local completion',
    [Text.UTF8Encoding]::new($false)
)
[Console]::Out.WriteLine('MEANDAI_ADOPTION_READY - mock local completion')
