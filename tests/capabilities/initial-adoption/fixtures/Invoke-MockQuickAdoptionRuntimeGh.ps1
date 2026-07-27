[CmdletBinding()]
param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments)

$ErrorActionPreference = 'Stop'
$mode = [string]$env:MEANDAI_TEST_RUNTIME_MODE
$bundlePath = [string]$env:MEANDAI_TEST_RUNTIME_BUNDLE
$bundleDigest = [string]$env:MEANDAI_TEST_RUNTIME_DIGEST
$bundleLength = [long]$env:MEANDAI_TEST_RUNTIME_LENGTH
$sourceCommit = [string]$env:MEANDAI_TEST_RUNTIME_COMMIT
$tag = 'v0.15.5'
$assetName = 'MeAndAI.QuickAdoption.Bundle.zip'

if ([string]$env:GH_HOST -cne 'github.com') {
    Write-Error "Bootstrap did not pin GH_HOST to github.com."
    exit 9
}
if ($mode -ceq 'RequireToken' -and
    [string]$env:GH_TOKEN -cne 'test-read-token') {
    Write-Error 'Bootstrap did not provision the exact local protocol-read token.'
    exit 10
}

if ($Arguments.Count -eq 1 -and $Arguments[0] -ceq '--version') {
    'gh version 2.82.1 (test)'
    exit 0
}
if ($Arguments.Count -eq 2 -and
    $Arguments[0] -ceq 'auth' -and $Arguments[1] -ceq 'status') {
    'Logged in to github.com as test-owner'
    exit 0
}

if ($Arguments.Count -ge 2 -and $Arguments[0] -ceq 'api') {
    $endpoint = [string]$Arguments[$Arguments.Count - 1]
    if ($endpoint -ceq "repos/hasanmanzak/meAndAI/releases/tags/$tag") {
        $asset = [ordered]@{
            name = $assetName
            size = if ($mode -ceq 'OversizeAsset') { 67108865 }
                else { $bundleLength }
            digest = if ($mode -ceq 'BadDigest') {
                'sha256:' + ('f' * 64)
            }
            else { 'sha256:' + $bundleDigest }
        }
        $assets = if ($mode -ceq 'DuplicateAsset') {
            @([pscustomobject]$asset, [pscustomobject]$asset)
        }
        else { @([pscustomobject]$asset) }
        [ordered]@{
            tag_name = $tag
            draft = $false
            prerelease = $false
            immutable = ($mode -cne 'MutableRelease')
            published_at = '2026-07-20T00:00:00Z'
            assets = $assets
        } | ConvertTo-Json -Depth 5 -Compress
        exit 0
    }
    if ($endpoint -ceq "repos/hasanmanzak/meAndAI/git/ref/tags/$tag") {
        [ordered]@{
            object = [ordered]@{ type = 'commit'; sha = $sourceCommit }
        } | ConvertTo-Json -Depth 3 -Compress
        exit 0
    }
    Write-Error "Unexpected fake GitHub API endpoint: $endpoint"
    exit 2
}

if ($Arguments.Count -ge 3 -and
    $Arguments[0] -ceq 'release' -and
    $Arguments[1] -ceq 'download' -and
    $Arguments[2] -ceq $tag) {
    if ($mode -ceq 'OversizeAsset') {
        Write-Error 'An oversized runtime asset must be rejected before download.'
        exit 11
    }
    $directoryIndex = [Array]::IndexOf($Arguments, '--dir')
    if ($directoryIndex -lt 0 -or $directoryIndex + 1 -ge $Arguments.Count) {
        Write-Error 'Fake release download lacks --dir.'
        exit 3
    }
    $destination = Join-Path $Arguments[$directoryIndex + 1] $assetName
    Copy-Item -LiteralPath $bundlePath -Destination $destination
    exit 0
}

Write-Error "Unexpected fake gh arguments: $($Arguments -join ' ')"
exit 4
