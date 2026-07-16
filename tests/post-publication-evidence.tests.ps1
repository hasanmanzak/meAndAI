[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/MeAndAI.ScenarioEvidence.psm1') -Force
$verifierPath = Join-Path $root 'tests/Verify-PostPublicationEvidence.ps1'
$failures = [System.Collections.Generic.List[string]]::new()
$global:MeAndAIPostPublicationMode = 'Valid'
$global:MeAndAIPostPublicationRequests = [System.Collections.Generic.List[string]]::new()

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

function global:Invoke-RestMethod {
    param(
        [string]$Method,
        [string]$Uri,
        [hashtable]$Headers
    )

    if ($Method -cne 'Get' -or
        $Headers.Authorization -cne 'Bearer test-token' -or
        $Headers['X-GitHub-Api-Version'] -cne '2026-03-10') {
        throw 'TEST-0076 verifier did not use the qualified read-only API contract.'
    }
    $global:MeAndAIPostPublicationRequests.Add($Uri)

    if ($Uri -ceq 'https://api.test/repos/example/meandai-consumer') {
        return [pscustomobject]@{ default_branch = 'main' }
    }
    if ($Uri -ceq 'https://api.test/repos/example/meandai-consumer/releases/tags/v1.2.3') {
        return [pscustomobject]@{
            tag_name = 'v1.2.3'
            draft = $false
            prerelease = $false
            published_at = '2026-07-16T00:00:00Z'
            immutable = ($global:MeAndAIPostPublicationMode -cne 'MutableRelease')
            target_commitish = $commit
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

    throw "TEST-0076 unexpected verifier request: $Uri"
}

function Invoke-PostPublicationScenario {
    param([Parameter(Mandatory)][string]$Mode)

    $global:MeAndAIPostPublicationMode = $Mode
    $global:MeAndAIPostPublicationRequests.Clear()
    try {
        & $verifierPath -Repository $repository -Tag $tag `
            -ExpectedCommit $commit -FeaturePath $featurePath `
            -IssueNumber $issueNumber -OwnedBranch $ownedBranch `
            -ApiBaseUri 'https://api.test' -Token 'test-token' 6>&1 | Out-Null
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
    }
}
finally {
    Remove-Item Function:\global:Invoke-RestMethod -ErrorAction SilentlyContinue
    Remove-Variable MeAndAIPostPublicationMode -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable MeAndAIPostPublicationRequests -Scope Global -ErrorAction SilentlyContinue
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
    -Owner 'tests/post-publication-evidence.tests.ps1' `
    -SourcePaths @($PSCommandPath) -AuthorityPath $scenarioAuthorityPath
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
