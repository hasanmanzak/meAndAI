[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
$verifierPath = Join-Path $root 'tests/capabilities/publication-evidence/Verify-PostPublicationEvidence.ps1'
$failures = [System.Collections.Generic.List[string]]::new()
$global:MeAndAIPostPublicationMode = 'Valid'
$global:MeAndAIPostPublicationRequests = [System.Collections.Generic.List[string]]::new()
$global:MeAndAIPostPublicationDownloadRequests = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

$repository = 'example/meandai-consumer'
$tag = 'v1.2.3'
$commit = '0123456789abcdef0123456789abcdef01234567'
$featurePath = 'docs/features/FEAT-0042-release-evidence/README.md'
$issueNumber = 42
$ownedBranch = 'codex/feat-0042-release-evidence'
$featureUrl = "https://github.com/$repository/blob/main/$featurePath"
$issueUrl = "https://github.com/$repository/issues/$issueNumber"
$releaseUrl = "https://github.com/$repository/releases/tag/$tag"
$commitUrl = "https://github.com/$repository/commit/$commit"
$launcherAssetName = 'Invoke-MeAndAIQuickAdoption.ps1'
$launcherSourcePath = 'scripts/Invoke-MeAndAIQuickAdoption.ps1'
$bundleAssetName = 'MeAndAI.QuickAdoption.Bundle.zip'
$bundleInventoryPath = 'scripts/quick-adoption/bundle.sources.json'
$bundleEntryPoint = 'MeAndAI.QuickAdoption/MeAndAI.QuickAdoption.psd1'
$bundleSources = @(
    $bundleEntryPoint,
    'MeAndAI.QuickAdoption/MeAndAI.QuickAdoption.psm1'
)
$global:MeAndAIPostPublicationLauncherSourceBytes = [Text.UTF8Encoding]::new($false).GetBytes(
    "[CmdletBinding()]`nparam()`nWrite-Host 'verified launcher fixture'`n"
)
$global:MeAndAIPostPublicationLauncherBytes =
    [byte[]]$global:MeAndAIPostPublicationLauncherSourceBytes.Clone()
$global:MeAndAIPostPublicationSourceBytes = @{
    $bundleEntryPoint = [Text.UTF8Encoding]::new($false).GetBytes(
        "@{ RootModule = 'MeAndAI.QuickAdoption.psm1'; ModuleVersion = '0.13.2' }`n"
    )
    'MeAndAI.QuickAdoption/MeAndAI.QuickAdoption.psm1' =
        [Text.UTF8Encoding]::new($false).GetBytes("function Invoke-TestRuntime { 'ok' }`n")
}

function Get-TestSha256 {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha256.ComputeHash($Bytes)) -replace '-', '').ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function New-TestQuickAdoptionBundleBytes {
    param(
        [string]$SourceCommit = $commit,
        [string]$RuntimeRepository = $repository,
        [string[]]$Sources = $bundleSources,
        [switch]$AlterSecondSource,
        [switch]$ReverseArchivePayload,
        [switch]$NonRegularPayload
    )

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $payloadBytes = @{}
    foreach ($source in $Sources) {
        $bytes = [byte[]]$global:MeAndAIPostPublicationSourceBytes[$source]
        if ($AlterSecondSource -and $source -ceq $bundleSources[1]) {
            $bytes = [Text.UTF8Encoding]::new($false).GetBytes(
                "function Invoke-TestRuntime { 'different release payload' }`n"
            )
        }
        $payloadBytes[$source] = $bytes
    }
    $manifest = [ordered]@{
        schema = 1
        kind = 'meandai.quick-adoption.module-bundle'
        runtimeRepository = $RuntimeRepository
        runtimeReleaseTag = $tag
        sourceCommit = $SourceCommit
        entryPoint = $bundleEntryPoint
        minimumPowerShellVersion = '5.1'
        payload = @($Sources | ForEach-Object {
            $bytes = [byte[]]$payloadBytes[$_]
            [ordered]@{
                path = $_
                length = [long]$bytes.LongLength
                sha256 = Get-TestSha256 -Bytes $bytes
            }
        })
    }
    $manifestBytes = [Text.UTF8Encoding]::new($false).GetBytes(
        ($manifest | ConvertTo-Json -Depth 8 -Compress)
    )
    $memory = [IO.MemoryStream]::new()
    $archive = [IO.Compression.ZipArchive]::new(
        $memory, [IO.Compression.ZipArchiveMode]::Create, $true,
        [Text.Encoding]::UTF8
    )
    try {
        $archiveSources = @($Sources)
        if ($ReverseArchivePayload) {
            [array]::Reverse($archiveSources)
        }
        foreach ($entrySource in @(
            [pscustomobject]@{ Path = 'manifest.json'; Bytes = $manifestBytes }
        ) + @($archiveSources | ForEach-Object {
            [pscustomobject]@{ Path = $_; Bytes = [byte[]]$payloadBytes[$_] }
        })) {
            $entry = $archive.CreateEntry([string]$entrySource.Path)
            if ($NonRegularPayload -and
                [string]$entrySource.Path -ceq [string]$bundleSources[1]) {
                $entry.ExternalAttributes = [int](0x1000 -shl 16)
            }
            $stream = $entry.Open()
            try {
                $bytes = [byte[]]$entrySource.Bytes
                $stream.Write($bytes, 0, $bytes.Length)
            }
            finally {
                $stream.Dispose()
            }
        }
    }
    finally {
        $archive.Dispose()
    }
    try {
        return $memory.ToArray()
    }
    finally {
        $memory.Dispose()
    }
}

function Set-TestAssetFixture {
    param([Parameter(Mandatory)][string]$Mode)

    $global:MeAndAIPostPublicationLauncherBytes =
        [byte[]]$global:MeAndAIPostPublicationLauncherSourceBytes.Clone()
    if ($Mode -ceq 'LauncherSourceMismatch') {
        $global:MeAndAIPostPublicationLauncherBytes =
            [Text.UTF8Encoding]::new($false).GetBytes(
                "[CmdletBinding()]`nparam()`nWrite-Host 'stale launcher asset'`n"
            )
    }
    $bundleParameters = @{}
    if ($Mode -ceq 'BundleWrongCommit') {
        $bundleParameters.SourceCommit = 'ffffffffffffffffffffffffffffffffffffffff'
    }
    elseif ($Mode -ceq 'BundleWrongIdentity') {
        $bundleParameters.RuntimeRepository = 'example/different-repository'
    }
    elseif ($Mode -ceq 'BundleInventoryMismatch') {
        $bundleParameters.Sources = @($bundleSources[0])
    }
    elseif ($Mode -ceq 'BundleSourceMismatch') {
        $bundleParameters.AlterSecondSource = $true
    }
    elseif ($Mode -ceq 'BundleEntryOrderMismatch') {
        $bundleParameters.ReverseArchivePayload = $true
    }
    elseif ($Mode -ceq 'BundleNonRegularEntry') {
        $bundleParameters.NonRegularPayload = $true
    }
    $global:MeAndAIPostPublicationBundleBytes = [byte[]](
        New-TestQuickAdoptionBundleBytes @bundleParameters
    )
}

function global:Invoke-RestMethod {
    param(
        [string]$Method,
        [string]$Uri,
        [hashtable]$Headers,
        [string]$OutFile
    )

    if ($Method -cne 'Get' -or
        $Headers.Authorization -cne 'Bearer test-token' -or
        $Headers['X-GitHub-Api-Version'] -cne '2026-03-10') {
        throw 'TEST-0076 verifier did not use the qualified read-only API contract.'
    }
    if ($PSBoundParameters.ContainsKey('OutFile')) {
        if ($Headers.Accept -cne 'application/octet-stream') {
            throw 'TEST-0147 release asset download did not request immutable bytes.'
        }
        $global:MeAndAIPostPublicationDownloadRequests.Add($Uri)
        $bytes = if ($Uri -ceq 'https://api.test/repos/example/meandai-consumer/releases/assets/101') {
            [byte[]]$global:MeAndAIPostPublicationLauncherBytes
        }
        elseif ($Uri -ceq 'https://api.test/repos/example/meandai-consumer/releases/assets/102') {
            if ($global:MeAndAIPostPublicationMode -ceq 'DownloadedDigestMismatch') {
                [Text.UTF8Encoding]::new($false).GetBytes('corrupted bundle download')
            }
            else {
                [byte[]]$global:MeAndAIPostPublicationBundleBytes
            }
        }
        else {
            throw "TEST-0147 unexpected release asset download: $Uri"
        }
        [IO.File]::WriteAllBytes($OutFile, $bytes)
        return
    }
    if ($Headers.Accept -cne 'application/vnd.github+json') {
        throw 'TEST-0076 verifier did not request GitHub JSON for evidence metadata.'
    }
    $global:MeAndAIPostPublicationRequests.Add($Uri)

    if ($Uri -ceq 'https://api.test/repos/example/meandai-consumer') {
        return [pscustomobject]@{ default_branch = 'main' }
    }
    if ($Uri -ceq 'https://api.test/repos/example/meandai-consumer/releases/tags/v1.2.3') {
        $launcherDigest = Get-TestSha256 -Bytes $global:MeAndAIPostPublicationLauncherBytes
        $bundleDigest = Get-TestSha256 -Bytes $global:MeAndAIPostPublicationBundleBytes
        if ($global:MeAndAIPostPublicationMode -ceq 'BadApiDigest') {
            $bundleDigest = 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
        }
        $assets = @(
            [pscustomobject]@{
                id = 101
                name = $launcherAssetName
                state = 'uploaded'
                size = if ($global:MeAndAIPostPublicationMode -ceq
                    'OversizedLauncherAsset') {
                    [long]1048577
                }
                else {
                    [long]$global:MeAndAIPostPublicationLauncherBytes.LongLength
                }
                digest = "sha256:$launcherDigest"
                url = 'https://api.test/repos/example/meandai-consumer/releases/assets/101'
            },
            [pscustomobject]@{
                id = 102
                name = $bundleAssetName
                state = 'uploaded'
                size = if ($global:MeAndAIPostPublicationMode -ceq
                    'OversizedBundleAsset') {
                    [long]67108865
                }
                else {
                    [long]$global:MeAndAIPostPublicationBundleBytes.LongLength
                }
                digest = "sha256:$bundleDigest"
                url = 'https://api.test/repos/example/meandai-consumer/releases/assets/102'
            }
        )
        if ($global:MeAndAIPostPublicationMode -ceq 'UnexpectedAsset') {
            $assets += [pscustomobject]@{
                id = 103
                name = 'unexpected.txt'
                state = 'uploaded'
                size = 1
                digest = "sha256:$('0' * 64)"
                url = 'https://api.test/repos/example/meandai-consumer/releases/assets/103'
            }
        }
        return [pscustomobject]@{
            tag_name = 'v1.2.3'
            draft = $false
            prerelease = $false
            published_at = '2026-07-16T00:00:00Z'
            immutable = ($global:MeAndAIPostPublicationMode -cne 'MutableRelease')
            target_commitish = $commit
            assets = $assets
        }
    }
    if ($Uri -ceq 'https://api.test/repos/example/meandai-consumer/git/ref/tags/v1.2.3') {
        return [pscustomobject]@{
            object = [pscustomobject]@{ type = 'commit'; sha = $commit }
        }
    }
    if ($Uri -ceq "https://api.test/repos/example/meandai-consumer/compare/$commit...main") {
        return [pscustomobject]@{
            status = if ($global:MeAndAIPostPublicationMode -ceq 'DivergedDefaultBranch') {
                'diverged'
            }
            else {
                'identical'
            }
            merge_base_commit = [pscustomobject]@{
                sha = if ($global:MeAndAIPostPublicationMode -ceq 'DivergedDefaultBranch') {
                    'ffffffffffffffffffffffffffffffffffffffff'
                }
                else {
                    $commit
                }
            }
        }
    }
    if ($Uri -ceq 'https://api.test/repos/example/meandai-consumer/git/matching-refs/heads/codex/feat-0042-release-evidence') {
        if ($global:MeAndAIPostPublicationMode -ceq 'OwnedBranchExists') {
            return ,([pscustomobject]@{ ref = "refs/heads/$ownedBranch" })
        }
        return @()
    }
    if ($Uri -ceq 'https://api.test/repos/example/meandai-consumer/issues/42') {
        $body = 'Publication evidence is recorded in issue comments.'
        if ($global:MeAndAIPostPublicationMode -ceq 'PageTwoCommentEvidence') {
            $body = 'Publication evidence is recorded in a paginated issue comment.'
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'IssueBodyOnlyEvidence') {
            $body = "$featureUrl`n$releaseUrl`n$commitUrl"
        }
        return [pscustomobject]@{ state = 'closed'; body = $body }
    }
    if ($Uri -match '^https://api\.test/repos/example/meandai-consumer/issues/42/comments\?per_page=100&page=(?<page>[1-9][0-9]*)$') {
        $page = [int]$Matches.page
        if ($global:MeAndAIPostPublicationMode -ceq 'PageTwoCommentEvidence') {
            if ($page -eq 1) {
                return @(1..100 | ForEach-Object {
                    [pscustomobject]@{ body = "unrelated comment $_" }
                })
            }
            if ($page -eq 2) {
                return ,([pscustomobject]@{
                    body = "$featureUrl`n$releaseUrl`n$commitUrl"
                })
            }
        }
        if ($page -eq 1 -and
            $global:MeAndAIPostPublicationMode -cne 'IssueBodyOnlyEvidence') {
            $commentBody = if ($global:MeAndAIPostPublicationMode -ceq 'MissingFeatureEvidence') {
                "$releaseUrl`n$commitUrl"
            }
            else {
                "$featureUrl`n$releaseUrl`n$commitUrl"
            }
            return ,([pscustomobject]@{ body = $commentBody })
        }
        return @()
    }
    if ($Uri -ceq "https://api.test/repos/example/meandai-consumer/contents/$featurePath`?ref=$commit") {
        $content = @"
# FEAT-0042 - Release evidence

| Field | Value |
| --- | --- |
| Status | Complete |
| Issue | [$issueNumber]($issueUrl) |
"@
        return [pscustomobject]@{
            encoding = 'base64'
            content = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($content))
        }
    }
    if ($Uri -ceq "https://api.test/repos/example/meandai-consumer/contents/$launcherSourcePath`?ref=$commit") {
        return [pscustomobject]@{
            encoding = 'base64'
            content = [Convert]::ToBase64String(
                [byte[]]$global:MeAndAIPostPublicationLauncherSourceBytes
            )
        }
    }
    if ($Uri -ceq "https://api.test/repos/example/meandai-consumer/contents/$bundleInventoryPath`?ref=$commit") {
        $inventory = [ordered]@{
            schema = 1
            kind = 'meandai.quick-adoption.bundle-sources'
            entryPoint = $bundleEntryPoint
            sources = $bundleSources
        }
        $content = $inventory | ConvertTo-Json -Depth 4
        return [pscustomobject]@{
            encoding = 'base64'
            content = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($content))
        }
    }
    foreach ($source in $bundleSources) {
        $sourceRepositoryPath = 'scripts/quick-adoption/' +
            $source.Substring('MeAndAI.QuickAdoption/'.Length)
        if ($Uri -ceq "https://api.test/repos/example/meandai-consumer/contents/$sourceRepositoryPath`?ref=$commit") {
            return [pscustomobject]@{
                encoding = 'base64'
                content = [Convert]::ToBase64String(
                    [byte[]]$global:MeAndAIPostPublicationSourceBytes[$source]
                )
            }
        }
    }

    throw "TEST-0076 unexpected verifier request: $Uri"
}

function Invoke-PostPublicationScenario {
    param(
        [Parameter(Mandatory)][string]$Mode,
        [switch]$VerifyAssets
    )

    $global:MeAndAIPostPublicationMode = $Mode
    $global:MeAndAIPostPublicationRequests.Clear()
    $global:MeAndAIPostPublicationDownloadRequests.Clear()
    Set-TestAssetFixture -Mode $Mode
    try {
        $parameters = @{
            Repository = $repository
            Tag = $tag
            ExpectedCommit = $commit
            FeaturePath = $featurePath
            IssueNumber = $issueNumber
            OwnedBranch = $ownedBranch
            ApiBaseUri = 'https://api.test'
            Token = 'test-token'
        }
        if ($VerifyAssets) {
            $parameters.ExpectedReleaseAssetNames = @(
                $launcherAssetName, $bundleAssetName
            )
            $parameters.ExpectedLauncherAssetName = $launcherAssetName
            $parameters.ExpectedLauncherSourcePath = $launcherSourcePath
            $parameters.ExpectedBundleAssetName = $bundleAssetName
            $parameters.ExpectedBundleSourceInventoryPath = $bundleInventoryPath
        }
        & $verifierPath @parameters 6>&1 | Out-Null
        return [pscustomobject]@{ Threw = $false; Error = '' }
    }
    catch {
        return [pscustomobject]@{ Threw = $true; Error = $_.Exception.Message }
    }
}

try {
    if (-not (Test-Path -LiteralPath $verifierPath -PathType Leaf)) {
        Add-Failure 'TEST-0076 post-publication verifier is missing.'
    }
    else {
        $valid = Invoke-PostPublicationScenario -Mode 'Valid'
        if ($valid.Threw) {
            Add-Failure "TEST-0076 valid published evidence failed: $($valid.Error)"
        }
        if ($global:MeAndAIPostPublicationDownloadRequests.Count -ne 0 -or
            @($global:MeAndAIPostPublicationRequests | Where-Object {
                $_ -match '/contents/scripts/quick-adoption/'
            }).Count -ne 0) {
            Add-Failure 'TEST-0147 historical verifier calls unexpectedly activated release-asset verification.'
        }
        $repositoryRootRequests = @($global:MeAndAIPostPublicationRequests |
            Where-Object {
                $_ -ceq 'https://api.test/repos/example/meandai-consumer'
            })
        $invalidTrailingRootRequests = @($global:MeAndAIPostPublicationRequests |
            Where-Object {
                $_ -ceq 'https://api.test/repos/example/meandai-consumer/'
            })
        if ($repositoryRootRequests.Count -ne 1 -or
            $invalidTrailingRootRequests.Count -ne 0) {
            Add-Failure 'TEST-0076 repository metadata endpoint used an invalid trailing slash.'
        }
        foreach ($requiredPath in @(
            '/releases/tags/v1.2.3', '/git/ref/tags/v1.2.3',
            "/compare/$commit...main",
            '/git/matching-refs/heads/codex/feat-0042-release-evidence',
            '/issues/42', '/issues/42/comments?per_page=100&page=1',
            "/contents/$featurePath`?ref=$commit"
        )) {
            if (@($global:MeAndAIPostPublicationRequests | Where-Object {
                $_.EndsWith($requiredPath, [StringComparison]::Ordinal)
            }).Count -ne 1) {
                Add-Failure "TEST-0076 verifier did not request exactly one '$requiredPath' evidence source."
            }
        }

        $pageTwoEvidence = Invoke-PostPublicationScenario -Mode 'PageTwoCommentEvidence'
        $commentPageRequests = @($global:MeAndAIPostPublicationRequests | Where-Object {
            $_ -match '/issues/42/comments\?per_page=100&page='
        })
        if ($pageTwoEvidence.Threw -or $commentPageRequests.Count -ne 2 -or
            $commentPageRequests[0] -cne 'https://api.test/repos/example/meandai-consumer/issues/42/comments?per_page=100&page=1' -or
            $commentPageRequests[1] -cne 'https://api.test/repos/example/meandai-consumer/issues/42/comments?per_page=100&page=2') {
            Add-Failure "TEST-0083 verifier did not find evidence located only in the second issue-comment page: $($pageTwoEvidence.Error)"
        }

        foreach ($negative in @(
            @{ Mode = 'MutableRelease'; Error = '*release is not immutable*' },
            @{ Mode = 'DivergedDefaultBranch'; Error = '*not the default-branch head or one of its ancestors*' },
            @{ Mode = 'OwnedBranchExists'; Error = '*owned working branch still exists*' },
            @{ Mode = 'MissingFeatureEvidence'; Error = '*does not link the canonical feature*' },
            @{ Mode = 'IssueBodyOnlyEvidence'; Error = '*does not link the canonical feature*' }
        )) {
            $result = Invoke-PostPublicationScenario -Mode $negative.Mode
            if (-not $result.Threw -or $result.Error -notlike $negative.Error) {
                Add-Failure "TEST-0076 $($negative.Mode) did not fail closed: $($result.Error)"
            }
        }

        $assetContract = Invoke-PostPublicationScenario -Mode 'Valid' -VerifyAssets
        if ($assetContract.Threw) {
            Add-Failure "TEST-0147 valid immutable release assets failed: $($assetContract.Error)"
        }
        if ($global:MeAndAIPostPublicationDownloadRequests.Count -ne 2 -or
            $global:MeAndAIPostPublicationDownloadRequests[0] -cne 'https://api.test/repos/example/meandai-consumer/releases/assets/101' -or
            $global:MeAndAIPostPublicationDownloadRequests[1] -cne 'https://api.test/repos/example/meandai-consumer/releases/assets/102') {
            Add-Failure 'TEST-0147 verifier did not download exactly the two declared immutable release assets.'
        }
        foreach ($requiredPath in @(
            "/contents/$launcherSourcePath`?ref=$commit",
            "/contents/$bundleInventoryPath`?ref=$commit",
            "/contents/scripts/quick-adoption/MeAndAI.QuickAdoption.psd1`?ref=$commit",
            "/contents/scripts/quick-adoption/MeAndAI.QuickAdoption.psm1`?ref=$commit"
        )) {
            if (@($global:MeAndAIPostPublicationRequests | Where-Object {
                $_.EndsWith($requiredPath, [StringComparison]::Ordinal)
            }).Count -ne 1) {
                Add-Failure "TEST-0147 verifier did not request exactly one '$requiredPath' bundle source authority."
            }
        }

        foreach ($negative in @(
            @{ Mode = 'UnexpectedAsset'; Error = '*exact expected asset inventory*' },
            @{ Mode = 'LauncherSourceMismatch'; Error = '*launcher asset*released source commit*' },
            @{ Mode = 'BadApiDigest'; Error = '*downloaded digest does not match*' },
            @{ Mode = 'DownloadedDigestMismatch'; Error = '*downloaded size does not match*' },
            @{ Mode = 'BundleWrongIdentity'; Error = '*manifest identity does not match*' },
            @{ Mode = 'BundleWrongCommit'; Error = '*source commit does not match*' },
            @{ Mode = 'BundleInventoryMismatch'; Error = '*payload inventory does not match*' },
            @{ Mode = 'BundleSourceMismatch'; Error = '*does not match the released source commit*' },
            @{ Mode = 'BundleEntryOrderMismatch'; Error = '*entry order differs*' },
            @{ Mode = 'BundleNonRegularEntry'; Error = '*not one regular file*' },
            @{ Mode = 'OversizedLauncherAsset'; Error = '*bounded size*' },
            @{ Mode = 'OversizedBundleAsset'; Error = '*bounded size*' }
        )) {
            $result = Invoke-PostPublicationScenario -Mode $negative.Mode -VerifyAssets
            if (-not $result.Threw -or $result.Error -notlike $negative.Error) {
                Add-Failure "TEST-0147 $($negative.Mode) did not fail closed: $($result.Error)"
            }
            if ($negative.Mode -ceq 'OversizedLauncherAsset' -and
                $global:MeAndAIPostPublicationDownloadRequests.Count -ne 0) {
                Add-Failure 'TEST-0147 oversized launcher metadata reached an asset download.'
            }
            if ($negative.Mode -ceq 'OversizedBundleAsset' -and
                @($global:MeAndAIPostPublicationDownloadRequests | Where-Object {
                    $_ -ceq 'https://api.test/repos/example/meandai-consumer/releases/assets/102'
                }).Count -ne 0) {
                Add-Failure 'TEST-0147 oversized bundle metadata reached its asset download.'
            }
        }
    }
}
finally {
    Remove-Item Function:\global:Invoke-RestMethod -ErrorAction SilentlyContinue
    Remove-Variable MeAndAIPostPublicationMode -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable MeAndAIPostPublicationRequests -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable MeAndAIPostPublicationDownloadRequests -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable MeAndAIPostPublicationLauncherBytes -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable MeAndAIPostPublicationLauncherSourceBytes -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable MeAndAIPostPublicationBundleBytes -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable MeAndAIPostPublicationSourceBytes -Scope Global -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    Write-Host "Post-publication evidence tests failed with $($failures.Count) problem(s):" `
        -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Post-publication verifier tests passed without claiming published-state evidence.' `
    -ForegroundColor Green
$scenarioResult = New-MeAndAIScenarioResult `
    -Owner 'tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1' `
    -SourcePaths @($PSCommandPath) -AuthorityPath $scenarioAuthorityPath
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
