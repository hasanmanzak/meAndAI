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
$pullRequestNumber = 43
$ownedBranch = 'codex/feat-0042-release-evidence'
$featureUrl = "https://github.com/$repository/blob/main/$featurePath"
$issueUrl = "https://github.com/$repository/issues/$issueNumber"
$pullRequestUrl = "https://github.com/$repository/pull/$pullRequestNumber"
$decisionPath = 'docs/decisions/DEC-0042-release-evidence.md'
$decisionUrl = "https://github.com/$repository/blob/main/$decisionPath"
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
        "@{ RootModule = 'MeAndAI.QuickAdoption.psm1'; ModuleVersion = '0.14.2' }`n"
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
        $body = "## Canonical records`n`n- [Feature]($featureUrl)`n- [Decision]($decisionUrl)`n- [Pull request]($pullRequestUrl)`n`nPublication evidence is recorded in issue comments."
        if ($global:MeAndAIPostPublicationMode -ceq 'PageTwoCommentEvidence') {
            $body = "## Canonical records`n`n- [Feature]($featureUrl)`n- [Decision]($decisionUrl)`n- [Pull request]($pullRequestUrl)`n`nPublication evidence is recorded in a paginated issue comment."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'FreeTextIssueFeature') {
            $body = "Feature: FEAT-0042`n- [Decision]($decisionUrl)`n- [Pull request]($pullRequestUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'MissingIssueDecision') {
            $body = "- [Feature]($featureUrl)`n- [Pull request]($pullRequestUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'IssueBodyOnlyEvidence') {
            $body = "- [Feature]($featureUrl)`n- [Decision]($decisionUrl)`n- [Pull request]($pullRequestUrl)`n$releaseUrl`n$commitUrl"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'IssueCommentOnlyPullLink') {
            $body = "- [Feature]($featureUrl)`n- [Decision]($decisionUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'OwnIssueIdentity') {
            $body += "`nThis is issue #$issueNumber."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'OwnIssueShorthand') {
            $body += "`nThis is issue-$issueNumber."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongKindOwnIssueIdentity') {
            $body += "`nThis is PR #$issueNumber."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongKindOwnIssueShorthand') {
            $body += "`nThis is PR-$issueNumber."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'EscapedStableId') {
            $body += "`nRelated record: FEAT\-0042."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'HtmlEntityStableId') {
            $body += "`nRelated record: FEAT&#45;0042."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'BareExactAutolinks') {
            $body = "$featureUrl`n$decisionUrl`n$pullRequestUrl"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'PullLinkPrefixCollision') {
            $body = "- [Feature]($featureUrl)`n- [Decision]($decisionUrl)`n- [Pull request](https://github.com/example/meandai-consumer/pull/430)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'HiddenFeatureLink') {
            $body = "<!-- [Feature]($featureUrl) -->`n- [Decision]($decisionUrl)`n- [Pull request]($pullRequestUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'EscapedFeatureLink') {
            $body = "\[Feature]($featureUrl)`n- [Decision]($decisionUrl)`n- [Pull request]($pullRequestUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'OddEscapeFeatureLink') {
            $body = "\\\[Feature]($featureUrl)`n- [Decision]($decisionUrl)`n- [Pull request]($pullRequestUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'EscapedReferenceFeatureLink') {
            $body = "\[Feature][feature]`n- [Decision]($decisionUrl)`n- [Pull request]($pullRequestUrl)`n`n[feature]: $featureUrl"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'EvenEscapeFeatureLink') {
            $body = "\\[Feature]($featureUrl)`n- [Decision]($decisionUrl)`n- [Pull request]($pullRequestUrl)"
        }
        return [pscustomobject]@{
            state = 'closed'
            title = if ($global:MeAndAIPostPublicationMode -ceq 'FeatureIssueIdentityTitle') {
                '[FEAT-0042] Immutable Release Evidence Contract'
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'LinkedRecordInIssueTitle') {
                "[DEC-0042]($decisionUrl)"
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'IssueTitleUrlPrefixCollision') {
                "https://github.com/$repository/issues/420"
            }
            else { '[BUG-0042] Release evidence' }
            body = $body
        }
    }
    if ($Uri -match '^https://api\.test/repos/example/meandai-consumer/issues/42/comments\?per_page=100&page=(?<page>[1-9][0-9]*)$') {
        $page = [int]$Matches.page
        if ($global:MeAndAIPostPublicationMode -ceq 'PageTwoCommentEvidence') {
            if ($page -eq 1) {
                return @(1..100 | ForEach-Object {
                    [pscustomobject]@{
                        id = 10000 + $_
                        body = "unrelated discussion item $_"
                    }
                })
            }
            if ($page -eq 2) {
                return ,([pscustomobject]@{
                    id = 10101
                    body = "$featureUrl`n$releaseUrl`n$commitUrl"
                })
            }
        }
        if ($page -eq 1 -and
            $global:MeAndAIPostPublicationMode -cne 'IssueBodyOnlyEvidence') {
            $commentBody = if ($global:MeAndAIPostPublicationMode -ceq 'MissingReleaseEvidence') {
                $commitUrl
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'FreeTextIssueComment') {
                "See issue $issueNumber.`n$releaseUrl`n$commitUrl"
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'FreeTextCommentHash') {
                "See comment #9002.`n$releaseUrl`n$commitUrl"
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongCommentTarget') {
                "See [comment #9001]($issueUrl).`n$releaseUrl`n$commitUrl"
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'IssueCommentOnlyPullLink') {
                "[Pull request]($pullRequestUrl)`n$releaseUrl`n$commitUrl"
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'ParentIssueCommentLabel') {
                "[issue #42 comment]($issueUrl#issuecomment-9001)`n$releaseUrl`n$commitUrl"
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongParentCommentLabel') {
                "[issue #99 comment]($issueUrl#issuecomment-9001)`n$releaseUrl`n$commitUrl"
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'OwnCommentIdentity') {
                "This is comment #9001.`n$releaseUrl`n$commitUrl"
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'OwnCommentShorthand') {
                "This is comment-9001.`n$releaseUrl`n$commitUrl"
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'OwnReviewShorthand') {
                "This is review-9001.`n$releaseUrl`n$commitUrl"
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongCommentShorthand') {
                "See comment-9002.`n$releaseUrl`n$commitUrl"
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongReviewShorthand') {
                "See review-9002.`n$releaseUrl`n$commitUrl"
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'UnusedDefinitionEvidence') {
                "[release]: $releaseUrl`n[commit]: $commitUrl"
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'WrappedReleaseUri') {
                "https://evidence.example/?next=$releaseUrl`n$commitUrl"
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'PunctuatedAutolinks') {
                "$releaseUrl.`n$commitUrl."
            }
            else {
                "$releaseUrl`n$commitUrl"
            }
            return ,([pscustomobject]@{ id = 9001; body = $commentBody })
        }
        return @()
    }
    if ($Uri -ceq 'https://api.test/repos/example/meandai-consumer/pulls/43') {
        $body = "- [Issue]($issueUrl)`n- [Feature]($featureUrl)`n- [Decision]($decisionUrl)"
        if ($global:MeAndAIPostPublicationMode -ceq 'FreeTextPullDecision') {
            $body = "- [Issue]($issueUrl)`n- [Feature]($featureUrl)`nDecision: DEC-0042"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongPullFeatureTarget') {
            $body = "- [Issue]($issueUrl)`n- [Feature](https://github.com/example/meandai-consumer/blob/main/docs/features/FEAT-9999-wrong/README.md)`n- [Decision]($decisionUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongAndCorrectPullFeatureTarget') {
            $body = "- [Issue]($issueUrl)`n- [FEAT-0042](https://github.com/example/meandai-consumer/blob/main/docs/features/FEAT-9999-wrong/README.md)`n- [Decision]($decisionUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'CodeFormattedFeatureLink') {
            $body = "- [Issue]($issueUrl)`n- ``[FEAT-0042]($featureUrl)```n- [Decision]($decisionUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'ReferenceStyleLinks') {
            $body = @"
- [Issue][delivery-issue]
- [Feature][]
- [Decision]

[delivery-issue]: $issueUrl
[Feature]: <$featureUrl>
[Decision]: $decisionUrl
"@
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'BareIssueHash') {
            $body += "`nRelated delivery record: #$issueNumber."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongNumericIssueLabel') {
            $body += "`n- [issue #$issueNumber](https://github.com/example/meandai-consumer/issues/99)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'RawDocumentPath') {
            $body += "`nSee docs/notes/release-evidence.md for context."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'CodeFormattedDocumentPath') {
            $body += "`nSee ``docs/notes/release-evidence.md`` for details."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'FreeTextDocumentTitle') {
            $body += "`nImmutable Release Evidence Contract is authoritative."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongDocumentTitleTarget') {
            $body += "`n[See Immutable Release Evidence Contract]($decisionUrl)."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'CodeFormattedDocumentTitle') {
            $body += "`n``Immutable Release Evidence Contract`` is authoritative."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'NonPermalinkCommentLabel') {
            $body += "`n[comment]($issueUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'NonPermalinkReviewLabel') {
            $body += "`n[review #123]($pullRequestUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongIssueIdentityTarget') {
            $body += "`n[BUG-0042](https://github.com/example/meandai-consumer/issues/99)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongTestTarget') {
            $body += "`n[TEST-0175](https://github.com/example/meandai-consumer/blob/main/docs/features/FEAT-9999-wrong/test-cases.md)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'RelativeGitHubLink') {
            $body += "`n[documentation](docs/features/FEAT-0042-release-evidence/README.md)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'UnresolvedReferenceLink') {
            $body += "`n[guide][missing-guide]"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'FreeTextPullBug') {
            $body += "`nRegression for BUG-0042."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'OwnPullIdentity') {
            $body += "`nThis is PR #$pullRequestNumber."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'OwnPullShorthand') {
            $body += "`nThis is PR-$pullRequestNumber."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongKindOwnPullIdentity') {
            $body += "`nThis is issue #$pullRequestNumber."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SameArtifactAndMailLinks') {
            $body += "`n[Details](#details) and [email](mailto:test@example.com)."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'CodeLiteralMarkdown') {
            $body += @"
``[string][int] [label][key] [x](y)``

~~~text
[string][int] [label][key] [x](y)
~~~

    [string][int] [label][key] [x](y)
"@
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongNestedDecisionRecordTarget') {
            $body += "`n[RISK-0043]($featureUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'BareExactAutolinks') {
            $body = "$issueUrl`n$featureUrl`n$decisionUrl"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'ExactVisibleUrlLink') {
            $body += "`n[$issueUrl]($issueUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'TildeAngleAutolink') {
            $body += "`n<https://example.com/~user/doc.md>"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'UnderscoreAngleAutolink') {
            $body += "`n<https://github.com/example/meandai-consumer/blob/$commit/__init__.md>"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'StarQueryAutolink') {
            $body += "`nhttps://example.com/doc.md?x=a*b"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'BalancedInlineDestination') {
            $body += "`n[guide](https://example.com/foo(and(bar)).md)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'AngleInlineDestination') {
            $body += "`n[guide](<https://example.com/foo(bar).md>)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'EscapedInlineDestination') {
            $body += "`n[guide](https://example.com/foo\(bar\).md)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'NestedInlineLabel') {
            $body += "`n[see [issue #42]]($issueUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'InvalidBareAutolinkBoundary') {
            $body += "`nx$issueUrl"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'InvalidBareAutolinkDomain') {
            $body += "`nhttps://localhost/doc.md"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'IssueLabelToCommentTarget') {
            $body += "`n[issue #42]($issueUrl#issuecomment-9001)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'StableIdToCommentTarget') {
            $body += "`n[BUG-0042]($issueUrl#issuecomment-9001)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'DoubleBacktickFeatureLink') {
            $body += "`n``[FEAT-0042]($featureUrl)``"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'TildeFenceFeatureLink') {
            $body += "`n~~~text`n[FEAT-0042]($featureUrl)`n~~~"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'CodeFormattedDocumentPseudoLink') {
            $body += "`n``[guide](docs/guide.md)``"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'IndentedCodeFeatureLink') {
            $body += "`n`n    [FEAT-0042]($featureUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'BlockquoteIndentedCodeFeatureLink') {
            $body += "`n>     [FEAT-0042]($featureUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'ListIndentedCodeFeatureLink') {
            $body += "`n-     [FEAT-0042]($featureUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SpacedFenceFeatureLink') {
            $body += "`n" + '   ```md' +
                "`n   [FEAT-0042]($featureUrl)`n   " + '```'
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'BlockquoteFenceFeatureLink') {
            $body += "`n" + '> ```md' +
                "`n> [FEAT-0042]($featureUrl)`n> " + '```'
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'ListFenceFeatureLink') {
            $body += "`n" + '- ```md' +
                "`n  [FEAT-0042]($featureUrl)`n  " + '```'
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'MultilineInlineCodeFeatureLink') {
            $body += "`n" + '`[FEAT-0042](' + $featureUrl +
                ")`ncontinued" + '`'
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'EscapedIssueNumber') {
            $body += "`nRelated issue \#$issueNumber."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'GitHubShorthand') {
            $body += "`nRelated GH-$issueNumber."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'RepositoryShorthand') {
            $body += "`nRelated meandai-consumer#$issueNumber."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'QualifiedRepositoryShorthand') {
            $body += "`nRelated example/meandai-consumer#$issueNumber."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'IssueHyphenShorthand') {
            $body += "`nRelated issue-$issueNumber."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'PullHyphenShorthand') {
            $body += "`nRelated PR-$issueNumber."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongShorthandTarget') {
            $body += "`n[PR-$pullRequestNumber]($issueUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongShorthandRepository') {
            $body += "`n[GH-$issueNumber](https://github.com/evil/other/issues/$issueNumber)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'WrongOwnerRepositoryShorthand') {
            $body += "`n[meandai-consumer#$issueNumber](https://github.com/evil/meandai-consumer/issues/$issueNumber)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'EscapedLabelWrongTarget') {
            $body += "`n[FEAT\-0042]($decisionUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'HtmlEntityLabelWrongTarget') {
            $body += "`n[FEAT&#45;0042]($decisionUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'NonRenderingHtmlFeatureLink') {
            $body += "`n<pre>[FEAT-0042]($featureUrl)</pre>"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'NonRenderingBlockHtmlFeatureLink') {
            $body += "`n<table>`n[FEAT-0042]($featureUrl)`n</table>"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'NonRenderingCustomHtmlFeatureLink') {
            $body += "`n<x-panel>`n[FEAT-0042]($featureUrl)`n</x-panel>"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'NonRenderingAttributedCustomHtmlFeatureLink') {
            $body += "`n<x-panel title='>'>`n[FEAT-0042]($featureUrl)`n</x-panel>"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'NonRenderingProcessingInstructionFeatureLink') {
            $body += "`n<?process`n[FEAT-0042]($featureUrl)`n?>"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'NonRenderingCdataFeatureLink') {
            $body += "`n<![CDATA[`n[FEAT-0042]($featureUrl)`n]]>"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'NonRenderingDeclarationFeatureLink') {
            $body += "`n<!DECLARATION`n[FEAT-0042]($featureUrl)`n>"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'BlockquoteNonRenderingHtmlFeatureLink') {
            $body += "`n> <x-panel>`n> [FEAT-0042]($featureUrl)`n>"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'ListNonRenderingHtmlFeatureLink') {
            $body += "`n- <div>`n  [FEAT-0042]($featureUrl)`n  </div>"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'InlineHtmlStableId') {
            $body += "`nRelated FEAT-<em>0042</em>."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'InlineHtmlAttributeStableId') {
            $body += "`nRelated FEAT-<span title='>'>0042</span>."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'InlineHtmlWrongTarget') {
            $body += "`n[FEAT-<em>0042</em>]($decisionUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'InlineCommentLabelWrongTarget') {
            $body += "`n[FEAT-<!--x-->0042]($decisionUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'InlineCodeLabelWrongTarget') {
            $body += "`n[FEAT-``0042``]($decisionUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'BoldStableId') {
            $body += "`nRelated FEAT-**0042**."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'BoldWrongTarget') {
            $body += "`n[FEAT-**0042**]($decisionUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'BoldIssueNumber') {
            $body += "`nRelated issue **#$issueNumber**."
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SplitStableIdWrongTarget') {
            $body += "`nFEAT-[0042]($decisionUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SplitIssueNumber') {
            $body += "`nissue [#$issueNumber]($issueUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'VisibleUrlWrongTarget') {
            $body += "`n[$issueUrl](https://github.com/evil/other/issues/99)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'VisiblePathWrongTarget') {
            $body += "`n[$decisionPath]($featureUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SplitUrlWrongTarget') {
            $body += "`nhttps://github.com/example/meandai-consumer/issues/[42](https://github.com/evil/other/issues/99)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SplitReferenceUrlWrongTarget') {
            $body += "`nhttps://github.com/example/meandai-consumer/issues/[42][wrong]`n`n[wrong]: https://github.com/evil/other/issues/99"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SplitInlineCommentUrl') {
            $body += "`nhttps://github.com/example/meandai-consumer/issues/<!-- -->42"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SplitInlineTagUrl') {
            $body += "`nhttps://github.com/example/meandai-consumer/issues/<em>42</em>"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SplitSchemeCommentUrl') {
            $body += "`nhttps<!-- -->://github.com/example/meandai-consumer/issues/42"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SplitSchemeTagUrl') {
            $body += "`nhtt<em>ps</em>://github.com/example/meandai-consumer/issues/42"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SplitEntityUrl') {
            $body += "`nhttps&#58;//github.com/example/meandai-consumer/issues/42"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SplitEmphasisUrl') {
            $body += "`nhttps://github.com/example/meandai-consumer/issues/**42**"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SplitStrikeUrl') {
            $body += "`nhttps://github.com/example/meandai-consumer/issues/~~42~~"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SplitUnderscoreUrl') {
            $body += "`nhttps://github.com/example/meandai-consumer/issues/__42__"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SplitDecimalEntitySchemeUrl') {
            $body += "`n&#104;ttps://github.com/example/meandai-consumer/issues/42"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'SplitHexEntitySchemeUrl') {
            $body += "`n&#x68;ttps://github.com/example/meandai-consumer/issues/42"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'DuplicateInlineTagUrl') {
            $body += "`nhttps://github.com/example/meandai-consumer/issues/<em>42</em>(https://github.com/example/meandai-consumer/issues/42)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'DuplicateSchemeCommentUrl') {
            $body += "`nhttps<!-- -->://github.com/example/meandai-consumer/issues/42(https://github.com/example/meandai-consumer/issues/42)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'DuplicateEmphasisUrl') {
            $body += "`nhttps://github.com/example/meandai-consumer/issues/**42**(https://github.com/example/meandai-consumer/issues/42)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'UnclosedHtmlCommentFeatureLink') {
            $body += "`n<!--`n[FEAT-0042]($featureUrl)"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'FootnoteFreeTextFeature') {
            $body += "`nText[^1]`n`n[^1]: FEAT-0042"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'UnusedCrossRecordDefinition') {
            $body += "`n`n[FEAT-0042]: $featureUrl"
        }
        elseif ($global:MeAndAIPostPublicationMode -ceq 'CapitalizedIssueNumber') {
            $body += "`nRelated Issue #$issueNumber."
        }
        return [pscustomobject]@{
            state = 'closed'
            title = if ($global:MeAndAIPostPublicationMode -ceq 'PullTitleRecord') {
                'Implement BUG-0042'
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'FeatureSubjectPullTitle') {
                'Immutable Release Evidence Contract'
            }
            elseif ($global:MeAndAIPostPublicationMode -ceq 'FreeTextPullOwnIdInComment') {
                '[FEAT-0042] Immutable Release Evidence Contract'
            }
            else { 'Publish release evidence' }
            merged_at = '2026-07-16T00:00:00Z'
            merge_commit_sha = $commit
            base = [pscustomobject]@{ ref = 'main' }
            body = $body
        }
    }
    if ($Uri -match '^https://api\.test/repos/example/meandai-consumer/issues/43/comments\?per_page=100&page=(?<page>[1-9][0-9]*)$') {
        if ([int]$Matches.page -eq 1) {
            if ($global:MeAndAIPostPublicationMode -ceq 'FreeTextPullConversation') {
                return ,([pscustomobject]@{
                    id = 9101
                    body = "See PR $pullRequestNumber."
                })
            }
            if ($global:MeAndAIPostPublicationMode -ceq 'WrongAndCorrectPullFeatureTarget') {
                return ,([pscustomobject]@{ id = 9101; body = $featureUrl })
            }
            if ($global:MeAndAIPostPublicationMode -ceq 'FreeTextPullOwnIdInComment') {
                return ,([pscustomobject]@{ id = 9101; body = 'FEAT-0042' })
            }
        }
        return @()
    }
    if ($Uri -match '^https://api\.test/repos/example/meandai-consumer/pulls/43/reviews\?per_page=100&page=(?<page>[1-9][0-9]*)$') {
        if ([int]$Matches.page -eq 1 -and
            $global:MeAndAIPostPublicationMode -ceq 'FreeTextReviewDecision') {
            return ,([pscustomobject]@{ id = 9201; body = 'Review follows DEC-0042.' })
        }
        return @()
    }
    if ($Uri -match '^https://api\.test/repos/example/meandai-consumer/pulls/43/comments\?per_page=100&page=(?<page>[1-9][0-9]*)$') {
        if ([int]$Matches.page -eq 1 -and
            $global:MeAndAIPostPublicationMode -ceq 'FreeTextInlineComment') {
            return ,([pscustomobject]@{ id = 9301; body = 'See comment #9001 and docs/decisions/DEC-0042-release-evidence.md.' })
        }
        return @()
    }
    if ($Uri -match "^https://api\.test/repos/example/meandai-consumer/commits/$commit/comments\?per_page=100&page=(?<page>[1-9][0-9]*)$") {
        if ([int]$Matches.page -eq 1 -and
            $global:MeAndAIPostPublicationMode -ceq 'FreeTextCommitComment') {
            return ,([pscustomobject]@{
                id = 9401
                body = 'The released commit follows DEC-0042.'
            })
        }
        return @()
    }
    if ($Uri -ceq "https://api.test/repos/example/meandai-consumer/contents/$featurePath`?ref=$commit") {
        $decisionLabel = if ($global:MeAndAIPostPublicationMode -ceq 'WrongDecisionLabel') {
            'DEC-0043'
        }
        else { 'DEC-0042' }
        $pullRequestField = if ($global:MeAndAIPostPublicationMode -ceq 'IssueCommentOnlyPullLink') {
            "Recorded through [$issueNumber]($issueUrl)"
        }
        else { "[$pullRequestNumber]($pullRequestUrl)" }
        $decisionField = if ($global:MeAndAIPostPublicationMode -ceq 'ReferenceStyleFeatureDecision') {
            "[$decisionLabel][decision]"
        }
        else { "[$decisionLabel](../../decisions/DEC-0042-release-evidence.md)" }
        $referenceDefinition = if ($global:MeAndAIPostPublicationMode -ceq 'ReferenceStyleFeatureDecision') {
            "`n[decision]: ../../decisions/DEC-0042-release-evidence.md"
        }
        else { '' }
        $content = @"
# FEAT-0042 - Immutable Release Evidence Contract

| Field | Value |
| --- | --- |
| Status | Complete |
| Issue | [$issueNumber]($issueUrl) |
| Pull request | $pullRequestField |
| Decisions | $decisionField |
| Tests | [TEST-0175](test-cases.md) |

## Risks

| ID | Risk |
| --- | --- |
| ``RISK-0042`` | Release evidence can drift |
$referenceDefinition
"@
        return [pscustomobject]@{
            encoding = 'base64'
            content = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($content))
        }
    }
    if ($Uri -ceq "https://api.test/repos/example/meandai-consumer/contents/$decisionPath`?ref=$commit") {
        return [pscustomobject]@{
            encoding = 'base64'
            content = [Convert]::ToBase64String(
                [Text.Encoding]::UTF8.GetBytes(
                    "# DEC-0042 - Release Evidence Authority`n`nRelated feature: [FEAT-0042](../features/FEAT-0042-release-evidence/README.md).`n`n| ID | Risk |`n| --- | --- |`n| ``RISK-0043`` | Publication authority can drift |`n"
                )
            )
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
            PullRequestNumber = $pullRequestNumber
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
            '/pulls/43', '/issues/43/comments?per_page=100&page=1',
            '/pulls/43/reviews?per_page=100&page=1',
            '/pulls/43/comments?per_page=100&page=1',
            "/commits/$commit/comments?per_page=100&page=1",
            "/contents/$featurePath`?ref=$commit",
            "/contents/$decisionPath`?ref=$commit"
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
        $referenceStyleEvidence = Invoke-PostPublicationScenario `
            -Mode 'ReferenceStyleLinks'
        if ($referenceStyleEvidence.Threw) {
            Add-Failure "TEST-0176 valid reference-style Markdown links failed: $($referenceStyleEvidence.Error)"
        }
        foreach ($positiveMode in @(
            'IssueCommentOnlyPullLink',
            'ParentIssueCommentLabel',
            'FeatureIssueIdentityTitle',
            'FeatureSubjectPullTitle',
            'ReferenceStyleFeatureDecision',
            'OwnIssueIdentity',
            'OwnPullIdentity',
            'OwnCommentIdentity',
            'OwnIssueShorthand',
            'OwnPullShorthand',
            'OwnCommentShorthand',
            'OwnReviewShorthand',
            'SameArtifactAndMailLinks',
            'CodeLiteralMarkdown',
            'BareExactAutolinks',
            'ExactVisibleUrlLink',
            'TildeAngleAutolink',
            'UnderscoreAngleAutolink',
            'StarQueryAutolink',
            'BalancedInlineDestination',
            'AngleInlineDestination',
            'EscapedInlineDestination',
            'NestedInlineLabel',
            'PunctuatedAutolinks',
            'EvenEscapeFeatureLink'
        )) {
            $positive = Invoke-PostPublicationScenario -Mode $positiveMode
            if ($positive.Threw) {
                Add-Failure "TEST-0176 valid $positiveMode evidence failed: $($positive.Error)"
            }
        }

        foreach ($negative in @(
            @{ Mode = 'MutableRelease'; Error = '*release is not immutable*' },
            @{ Mode = 'DivergedDefaultBranch'; Error = '*not the default-branch head or one of its ancestors*' },
            @{ Mode = 'OwnedBranchExists'; Error = '*owned working branch still exists*' },
            @{ Mode = 'MissingReleaseEvidence'; Error = '*does not contain the immutable release link*' },
            @{ Mode = 'UnusedDefinitionEvidence'; Error = '*does not contain the immutable release link*' },
            @{ Mode = 'WrappedReleaseUri'; Error = '*does not contain the immutable release link*' },
            @{ Mode = 'IssueBodyOnlyEvidence'; Error = '*does not contain the immutable release link*' },
            @{ Mode = 'MissingIssueDecision'; Error = '*does not link canonical decision*' },
            @{ Mode = 'FreeTextIssueFeature'; Error = '*free-text cross-record reference*' },
            @{ Mode = 'FreeTextPullDecision'; Error = '*free-text cross-record reference*' },
            @{ Mode = 'WrongPullFeatureTarget'; Error = '*does not link the canonical feature*' },
            @{ Mode = 'FreeTextIssueComment'; Error = '*free-text cross-record reference*' },
            @{ Mode = 'FreeTextCommentHash'; Error = '*without an exact permalink*' },
            @{ Mode = 'WrongCommentTarget'; Error = '*not an exact GitHub comment permalink*' },
            @{ Mode = 'WrongParentCommentLabel'; Error = '*comment parent label*does not match*' },
            @{ Mode = 'FreeTextPullConversation'; Error = '*free-text cross-record reference*' },
            @{ Mode = 'FreeTextPullOwnIdInComment'; Error = '*free-text cross-record reference*' },
            @{ Mode = 'FreeTextReviewDecision'; Error = '*free-text cross-record reference*' },
            @{ Mode = 'FreeTextInlineComment'; Error = '*without an exact permalink*' },
            @{ Mode = 'FreeTextCommitComment'; Error = '*free-text cross-record reference*' },
            @{ Mode = 'WrongAndCorrectPullFeatureTarget'; Error = '*other than its exact canonical target*' },
            @{ Mode = 'CodeFormattedFeatureLink'; Error = '*code-formatted cross-record reference*' },
            @{ Mode = 'CodeFormattedDocumentPath'; Error = '*code-formatted cross-record reference*' },
            @{ Mode = 'FreeTextDocumentTitle'; Error = '*free-text document-title reference*' },
            @{ Mode = 'CodeFormattedDocumentTitle'; Error = '*code-formatted cross-record reference*' },
            @{ Mode = 'WrongDocumentTitleTarget'; Error = '*document title*other than its exact canonical target*' },
            @{ Mode = 'NonPermalinkCommentLabel'; Error = '*not an exact GitHub comment permalink*' },
            @{ Mode = 'NonPermalinkReviewLabel'; Error = '*not an exact GitHub comment permalink*' },
            @{ Mode = 'WrongIssueIdentityTarget'; Error = '*BUG-0042*other than its exact canonical target*' },
            @{ Mode = 'WrongTestTarget'; Error = '*TEST-0175*other than its exact canonical target*' },
            @{ Mode = 'RelativeGitHubLink'; Error = '*relative repository-document link*' },
            @{ Mode = 'UnresolvedReferenceLink'; Error = '*unresolved reference-style link*' },
            @{ Mode = 'BareIssueHash'; Error = '*free-text cross-record reference by number*' },
            @{ Mode = 'WrongNumericIssueLabel'; Error = '*numeric link label*does not match*' },
            @{ Mode = 'RawDocumentPath'; Error = '*free-text repository document path*' },
            @{ Mode = 'FreeTextPullBug'; Error = '*free-text cross-record reference*' },
            @{ Mode = 'PullTitleRecord'; Error = '*cross-record identifier on a non-rendering title surface*' },
            @{ Mode = 'WrongKindOwnIssueIdentity'; Error = '*free-text cross-record reference by number*' },
            @{ Mode = 'WrongKindOwnPullIdentity'; Error = '*free-text cross-record reference by number*' },
            @{ Mode = 'WrongKindOwnIssueShorthand'; Error = '*free-text GitHub shorthand reference*' },
            @{ Mode = 'WrongNestedDecisionRecordTarget'; Error = '*RISK-0043*other than its exact canonical target*' },
            @{ Mode = 'PullLinkPrefixCollision'; Error = '*does not link the delivery pull request*' },
            @{ Mode = 'HiddenFeatureLink'; Error = '*hides a cross-record reference*' },
            @{ Mode = 'EscapedFeatureLink'; Error = '*does not link the canonical feature*' },
            @{ Mode = 'OddEscapeFeatureLink'; Error = '*does not link the canonical feature*' },
            @{ Mode = 'EscapedReferenceFeatureLink'; Error = '*unused reference-link definition*' },
            @{ Mode = 'IssueLabelToCommentTarget'; Error = '*numeric label for a comment target*' },
            @{ Mode = 'StableIdToCommentTarget'; Error = '*BUG-0042*other than its exact canonical target*' },
            @{ Mode = 'DoubleBacktickFeatureLink'; Error = '*code-formatted cross-record reference*' },
            @{ Mode = 'TildeFenceFeatureLink'; Error = '*code-formatted cross-record reference*' },
            @{ Mode = 'CodeFormattedDocumentPseudoLink'; Error = '*code-formatted cross-record reference*' },
            @{ Mode = 'IndentedCodeFeatureLink'; Error = '*code-formatted cross-record reference*' },
            @{ Mode = 'BlockquoteIndentedCodeFeatureLink'; Error = '*code-formatted cross-record reference*' },
            @{ Mode = 'ListIndentedCodeFeatureLink'; Error = '*code-formatted cross-record reference*' },
            @{ Mode = 'SpacedFenceFeatureLink'; Error = '*code-formatted cross-record reference*' },
            @{ Mode = 'BlockquoteFenceFeatureLink'; Error = '*code-formatted cross-record reference*' },
            @{ Mode = 'ListFenceFeatureLink'; Error = '*code-formatted cross-record reference*' },
            @{ Mode = 'MultilineInlineCodeFeatureLink'; Error = '*code-formatted cross-record reference*' },
            @{ Mode = 'EscapedStableId'; Error = '*free-text cross-record reference*' },
            @{ Mode = 'HtmlEntityStableId'; Error = '*free-text cross-record reference*' },
            @{ Mode = 'EscapedIssueNumber'; Error = '*free-text cross-record reference by number*' },
            @{ Mode = 'GitHubShorthand'; Error = '*free-text GitHub shorthand reference*' },
            @{ Mode = 'RepositoryShorthand'; Error = '*free-text GitHub shorthand reference*' },
            @{ Mode = 'QualifiedRepositoryShorthand'; Error = '*free-text GitHub shorthand reference*' },
            @{ Mode = 'IssueHyphenShorthand'; Error = '*free-text GitHub shorthand reference*' },
            @{ Mode = 'PullHyphenShorthand'; Error = '*free-text GitHub shorthand reference*' },
            @{ Mode = 'WrongCommentShorthand'; Error = '*free-text GitHub shorthand reference*' },
            @{ Mode = 'WrongReviewShorthand'; Error = '*free-text GitHub shorthand reference*' },
            @{ Mode = 'WrongShorthandTarget'; Error = '*other than its exact GitHub record*' },
            @{ Mode = 'WrongShorthandRepository'; Error = '*other than its exact GitHub record*' },
            @{ Mode = 'WrongOwnerRepositoryShorthand'; Error = '*other than its exact GitHub record*' },
            @{ Mode = 'EscapedLabelWrongTarget'; Error = '*FEAT-0042*other than its exact canonical target*' },
            @{ Mode = 'HtmlEntityLabelWrongTarget'; Error = '*FEAT-0042*other than its exact canonical target*' },
            @{ Mode = 'LinkedRecordInIssueTitle'; Error = '*titles do not render clickable links*' },
            @{ Mode = 'IssueTitleUrlPrefixCollision'; Error = '*URL on a non-rendering title surface*' },
            @{ Mode = 'NonRenderingHtmlFeatureLink'; Error = '*inside non-rendering HTML*' },
            @{ Mode = 'NonRenderingBlockHtmlFeatureLink'; Error = '*inside non-rendering HTML*' },
            @{ Mode = 'NonRenderingCustomHtmlFeatureLink'; Error = '*inside non-rendering HTML*' },
            @{ Mode = 'NonRenderingAttributedCustomHtmlFeatureLink'; Error = '*inside non-rendering HTML*' },
            @{ Mode = 'NonRenderingProcessingInstructionFeatureLink'; Error = '*inside non-rendering HTML*' },
            @{ Mode = 'NonRenderingCdataFeatureLink'; Error = '*inside non-rendering HTML*' },
            @{ Mode = 'NonRenderingDeclarationFeatureLink'; Error = '*inside non-rendering HTML*' },
            @{ Mode = 'BlockquoteNonRenderingHtmlFeatureLink'; Error = '*inside non-rendering HTML*' },
            @{ Mode = 'ListNonRenderingHtmlFeatureLink'; Error = '*inside non-rendering HTML*' },
            @{ Mode = 'InlineHtmlStableId'; Error = '*free-text cross-record reference*' },
            @{ Mode = 'InlineHtmlAttributeStableId'; Error = '*free-text cross-record reference*' },
            @{ Mode = 'InlineHtmlWrongTarget'; Error = '*FEAT-0042*other than its exact canonical target*' },
            @{ Mode = 'InlineCommentLabelWrongTarget'; Error = '*FEAT-0042*other than its exact canonical target*' },
            @{ Mode = 'InlineCodeLabelWrongTarget'; Error = '*FEAT-0042*other than its exact canonical target*' },
            @{ Mode = 'BoldStableId'; Error = '*free-text cross-record reference*' },
            @{ Mode = 'BoldWrongTarget'; Error = '*FEAT-0042*other than its exact canonical target*' },
            @{ Mode = 'BoldIssueNumber'; Error = '*free-text cross-record reference by number*' },
            @{ Mode = 'SplitStableIdWrongTarget'; Error = '*not wholly covered by one clickable link*' },
            @{ Mode = 'SplitIssueNumber'; Error = '*not wholly covered by one clickable link*' },
            @{ Mode = 'VisibleUrlWrongTarget'; Error = '*links visible URL*different target*' },
            @{ Mode = 'VisiblePathWrongTarget'; Error = '*links visible repository-document path*different target*' },
            @{ Mode = 'SplitUrlWrongTarget'; Error = '*composes a visible URL across a partial Markdown link*' },
            @{ Mode = 'SplitReferenceUrlWrongTarget'; Error = '*composes a visible URL across a partial Markdown link*' },
            @{ Mode = 'SplitInlineCommentUrl'; Error = '*visible URL*not wholly covered*' },
            @{ Mode = 'SplitInlineTagUrl'; Error = '*visible URL*not wholly covered*' },
            @{ Mode = 'SplitSchemeCommentUrl'; Error = '*visible URL*not wholly covered*' },
            @{ Mode = 'SplitSchemeTagUrl'; Error = '*visible URL*not wholly covered*' },
            @{ Mode = 'SplitEntityUrl'; Error = '*visible URL*not wholly covered*' },
            @{ Mode = 'SplitEmphasisUrl'; Error = '*visible URL*not wholly covered*' },
            @{ Mode = 'SplitStrikeUrl'; Error = '*visible URL*not wholly covered*' },
            @{ Mode = 'SplitUnderscoreUrl'; Error = '*visible URL*not wholly covered*' },
            @{ Mode = 'SplitDecimalEntitySchemeUrl'; Error = '*visible URL*not wholly covered*' },
            @{ Mode = 'SplitHexEntitySchemeUrl'; Error = '*visible URL*not wholly covered*' },
            @{ Mode = 'DuplicateInlineTagUrl'; Error = '*visible URL*not wholly covered*' },
            @{ Mode = 'DuplicateSchemeCommentUrl'; Error = '*visible URL*not wholly covered*' },
            @{ Mode = 'DuplicateEmphasisUrl'; Error = '*visible URL*not wholly covered*' },
            @{ Mode = 'InvalidBareAutolinkBoundary'; Error = '*visible URL*not wholly covered*' },
            @{ Mode = 'InvalidBareAutolinkDomain'; Error = '*visible URL*not wholly covered*' },
            @{ Mode = 'UnclosedHtmlCommentFeatureLink'; Error = '*hides a cross-record reference*' },
            @{ Mode = 'FootnoteFreeTextFeature'; Error = '*free-text cross-record reference*' },
            @{ Mode = 'UnusedCrossRecordDefinition'; Error = '*unused reference-link definition*' },
            @{ Mode = 'CapitalizedIssueNumber'; Error = '*free-text cross-record reference by number*' },
            @{ Mode = 'WrongDecisionLabel'; Error = '*label does not match*' }
        )) {
            $result = Invoke-PostPublicationScenario -Mode $negative.Mode
            if (-not $result.Threw -or $result.Error -notlike $negative.Error) {
                Add-Failure "TEST-0176 $($negative.Mode) did not fail closed: $($result.Error)"
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
