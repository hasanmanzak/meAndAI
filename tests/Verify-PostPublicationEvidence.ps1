[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Repository,
    [Parameter(Mandatory)][string]$Tag,
    [Parameter(Mandatory)][string]$ExpectedCommit,
    [Parameter(Mandatory)][string]$FeaturePath,
    [Parameter(Mandatory)][ValidateRange(1, [int]::MaxValue)][int]$IssueNumber,
    [Parameter(Mandatory)][string]$OwnedBranch,
    [string]$DefaultBranch = 'main',
    [string]$ApiBaseUri = 'https://api.github.com',
    [string]$Token = $(if ($env:GH_TOKEN) { $env:GH_TOKEN } else { $env:GITHUB_TOKEN })
)

$ErrorActionPreference = 'Stop'

function Assert-PostPublicationCondition {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )

    if (-not $Condition) {
        throw "TEST-0065 $Message"
    }
}

function ConvertTo-ApiPath {
    param([Parameter(Mandatory)][string]$Value)

    return (($Value -split '/') | ForEach-Object {
        [uri]::EscapeDataString($_)
    }) -join '/'
}

Assert-PostPublicationCondition ($Repository -cmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') `
    'repository must be an exact owner/name identity.'
Assert-PostPublicationCondition ($Tag -cmatch '^v(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)$') `
    'release tag must be canonical.'
Assert-PostPublicationCondition ($ExpectedCommit -cmatch '^[0-9a-f]{40}$') `
    'expected commit must be a full lowercase SHA.'
Assert-PostPublicationCondition ($DefaultBranch -cmatch '^[A-Za-z0-9._/-]+$') `
    'default branch contains unsupported characters.'
Assert-PostPublicationCondition ($OwnedBranch -cmatch '^[A-Za-z0-9._/-]+$') `
    'owned branch contains unsupported characters.'
Assert-PostPublicationCondition `
    ($FeaturePath -cmatch '^docs/features/FEAT-\d{4}-[A-Za-z0-9._-]+/README\.md$') `
    'feature path must identify one canonical feature record.'
Assert-PostPublicationCondition (-not [string]::IsNullOrWhiteSpace($Token)) `
    'GitHub API token is required for authoritative post-publication evidence.'

$headers = @{
    Accept = 'application/vnd.github+json'
    Authorization = "Bearer $Token"
    'User-Agent' = 'meAndAI-post-publication-verifier'
    'X-GitHub-Api-Version' = '2026-03-10'
}
$apiRoot = $ApiBaseUri.TrimEnd('/')
$repositoryApi = "$apiRoot/repos/$Repository"

function Invoke-GitHubGet {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Path)

    $uri = if ([string]::IsNullOrEmpty($Path)) {
        $repositoryApi
    }
    else {
        "$repositoryApi/$Path"
    }
    return Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
}

function Invoke-GitHubPagedGet {
    param(
        [Parameter(Mandatory)][string]$Path,
        [ValidateRange(1, 100)][int]$MaximumPages = 100
    )

    $results = [System.Collections.Generic.List[object]]::new()
    for ($page = 1; $page -le $MaximumPages; $page++) {
        $items = @(Invoke-GitHubGet "$Path`?per_page=100&page=$page")
        foreach ($item in $items) {
            if ($null -ne $item) {
                $results.Add($item)
            }
        }
        if ($items.Count -lt 100) {
            return @($results)
        }
    }
    throw "TEST-0065 GitHub pagination exceeded the bounded $MaximumPages-page evidence limit."
}

$encodedTag = ConvertTo-ApiPath $Tag
$encodedDefaultBranch = ConvertTo-ApiPath $DefaultBranch
$encodedOwnedBranch = ConvertTo-ApiPath $OwnedBranch
$encodedFeaturePath = ConvertTo-ApiPath $FeaturePath

$repositoryState = Invoke-GitHubGet ''
Assert-PostPublicationCondition ($repositoryState.default_branch -ceq $DefaultBranch) `
    "repository default branch is not '$DefaultBranch'."

$release = Invoke-GitHubGet "releases/tags/$encodedTag"
Assert-PostPublicationCondition ($release.tag_name -ceq $Tag) `
    'release tag identity does not match the requested tag.'
Assert-PostPublicationCondition (-not [bool]$release.draft) `
    'release is still a draft.'
Assert-PostPublicationCondition (-not [bool]$release.prerelease) `
    'release is marked as a prerelease.'
Assert-PostPublicationCondition ($null -ne $release.published_at) `
    'release has no publication timestamp.'
Assert-PostPublicationCondition `
    ($null -ne $release.PSObject.Properties['immutable'] -and [bool]$release.immutable) `
    'release is not immutable.'
Assert-PostPublicationCondition ($release.target_commitish -ceq $ExpectedCommit) `
    'release target is not the exact expected commit.'

$tagReference = Invoke-GitHubGet "git/ref/tags/$encodedTag"
$tagObject = $tagReference.object
for ($depth = 0; $tagObject.type -ceq 'tag' -and $depth -lt 5; $depth++) {
    $annotatedTag = Invoke-GitHubGet "git/tags/$($tagObject.sha)"
    $tagObject = $annotatedTag.object
}
Assert-PostPublicationCondition ($tagObject.type -ceq 'commit') `
    'tag does not resolve to a commit within the bounded peel depth.'
Assert-PostPublicationCondition ($tagObject.sha -ceq $ExpectedCommit) `
    'release tag does not resolve to the expected commit.'

$defaultBranchComparison = Invoke-GitHubGet "compare/$ExpectedCommit...$encodedDefaultBranch"
Assert-PostPublicationCondition `
    (@('identical', 'ahead') -ccontains $defaultBranchComparison.status -and
        $defaultBranchComparison.merge_base_commit.sha -ceq $ExpectedCommit) `
    'released commit is not the default-branch head or one of its ancestors.'

$matchingBranches = @(Invoke-GitHubGet "git/matching-refs/heads/$encodedOwnedBranch")
$ownedReference = "refs/heads/$OwnedBranch"
Assert-PostPublicationCondition `
    (@($matchingBranches | Where-Object { $_.ref -ceq $ownedReference }).Count -eq 0) `
    'owned working branch still exists after publication.'

$issue = Invoke-GitHubGet "issues/$IssueNumber"
Assert-PostPublicationCondition ($issue.state -ceq 'closed') `
    'canonical delivery issue is not closed.'
Assert-PostPublicationCondition ($null -eq $issue.PSObject.Properties['pull_request']) `
    'canonical delivery authority resolves to a pull request instead of an issue.'
$comments = @(Invoke-GitHubPagedGet "issues/$IssueNumber/comments")
$issueEvidence = @($comments | ForEach-Object { $_.body }) -join "`n"

$featureRecord = Invoke-GitHubGet "contents/$encodedFeaturePath`?ref=$ExpectedCommit"
Assert-PostPublicationCondition ($featureRecord.encoding -ceq 'base64') `
    'canonical feature record was not returned as base64 content.'
$featureBytes = [Convert]::FromBase64String(($featureRecord.content -replace '\s', ''))
$featureContent = [Text.Encoding]::UTF8.GetString($featureBytes)

$webRoot = "https://github.com/$Repository"
$issueUrl = "$webRoot/issues/$IssueNumber"
$releaseUrl = "$webRoot/releases/tag/$Tag"
$commitUrl = "$webRoot/commit/$ExpectedCommit"
$featureUrl = "$webRoot/blob/$DefaultBranch/$FeaturePath"

Assert-PostPublicationCondition `
    ([regex]::IsMatch($featureContent, '(?m)^\|\s*Status\s*\|\s*Complete\s*\|\s*$')) `
    'canonical feature record is not complete.'
Assert-PostPublicationCondition ($featureContent.Contains($issueUrl)) `
    'canonical feature record does not link its delivery issue.'
Assert-PostPublicationCondition ($issueEvidence.Contains($featureUrl)) `
    'delivery issue does not link the canonical feature record on the default branch.'
Assert-PostPublicationCondition ($issueEvidence.Contains($releaseUrl)) `
    'delivery issue does not contain the immutable release link.'
Assert-PostPublicationCondition ($issueEvidence.Contains($commitUrl)) `
    'delivery issue does not contain the exact released commit link.'

Write-Host "TEST-0065 post-publication evidence verified for $Repository $Tag at $ExpectedCommit." `
    -ForegroundColor Green
