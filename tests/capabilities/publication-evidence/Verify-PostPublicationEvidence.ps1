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
    [string]$Token = $(if ($env:GH_TOKEN) { $env:GH_TOKEN } else { $env:GITHUB_TOKEN }),
    [string[]]$ExpectedReleaseAssetNames = @(),
    [string]$ExpectedLauncherAssetName = 'Invoke-MeAndAIQuickAdoption.ps1',
    [string]$ExpectedLauncherSourcePath = 'scripts/Invoke-MeAndAIQuickAdoption.ps1',
    [string]$ExpectedBundleAssetName = '',
    [string]$ExpectedBundleSourceInventoryPath = 'scripts/quick-adoption/bundle.sources.json'
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

$expectedAssetNames = @($ExpectedReleaseAssetNames)
Assert-PostPublicationCondition ($expectedAssetNames.Count -le 16) `
    'expected release asset inventory exceeds the bounded 16-asset limit.'
$expectedAssetSet = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::Ordinal
)
foreach ($assetName in $expectedAssetNames) {
    Assert-PostPublicationCondition `
        (-not [string]::IsNullOrWhiteSpace($assetName) -and
            $assetName -cmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$' -and
            $expectedAssetSet.Add($assetName)) `
        "expected release asset name '$assetName' is unsafe or duplicated."
}
if ($expectedAssetSet.Contains($ExpectedLauncherAssetName)) {
    Assert-PostPublicationCondition `
        ($ExpectedLauncherSourcePath -cmatch
            '^(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+$' -and
            -not $ExpectedLauncherSourcePath.Contains('..') -and
            -not $ExpectedLauncherSourcePath.Contains('\')) `
        'expected launcher source path is unsafe.'
}
if (-not [string]::IsNullOrEmpty($ExpectedBundleAssetName)) {
    Assert-PostPublicationCondition `
        ($expectedAssetSet.Contains($ExpectedBundleAssetName)) `
        'expected bundle asset must be present in the expected release asset inventory.'
    Assert-PostPublicationCondition `
        ($ExpectedBundleSourceInventoryPath -cmatch
            '^(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+$' -and
            -not $ExpectedBundleSourceInventoryPath.Contains('..') -and
            -not $ExpectedBundleSourceInventoryPath.Contains('\')) `
        'expected bundle source inventory path is unsafe.'
}

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

function Get-Sha256Hex {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha256.ComputeHash($Bytes)) -replace '-', '').ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Get-GitHubContentBytes {
    param([Parameter(Mandatory)][string]$RepositoryPath)

    $encodedPath = ConvertTo-ApiPath $RepositoryPath
    $contentRecord = Invoke-GitHubGet "contents/$encodedPath`?ref=$ExpectedCommit"
    Assert-PostPublicationCondition ($contentRecord.encoding -ceq 'base64') `
        "released source '$RepositoryPath' was not returned as base64 content."
    try {
        return [Convert]::FromBase64String(
            ([string]$contentRecord.content -replace '\s', '')
        )
    }
    catch {
        throw "TEST-0065 released source '$RepositoryPath' contains invalid base64 content."
    }
}

function Read-ZipEntryBytes {
    param(
        [Parameter(Mandatory)][IO.Compression.ZipArchiveEntry]$Entry,
        [ValidateRange(0, 67108864)][long]$MaximumLength = 16777216
    )

    Assert-PostPublicationCondition ($Entry.Length -le $MaximumLength) `
        "bundle entry '$($Entry.FullName)' exceeds the bounded size limit."
    $stream = $Entry.Open()
    $memory = [IO.MemoryStream]::new()
    try {
        $buffer = [byte[]]::new(81920)
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            Assert-PostPublicationCondition `
                (($memory.Length + $read) -le $MaximumLength) `
                "bundle entry '$($Entry.FullName)' exceeded its bounded read limit."
            $memory.Write($buffer, 0, $read)
        }
        Assert-PostPublicationCondition ($memory.Length -eq $Entry.Length) `
            "bundle entry '$($Entry.FullName)' decompressed to an unexpected length."
        return $memory.ToArray()
    }
    finally {
        $memory.Dispose()
        $stream.Dispose()
    }
}

function Assert-QuickAdoptionBundle {
    param([Parameter(Mandatory)][string]$BundlePath)

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $fileStream = [IO.File]::Open(
        $BundlePath, [IO.FileMode]::Open, [IO.FileAccess]::Read,
        [IO.FileShare]::Read
    )
    $archive = $null
    try {
        $archive = [IO.Compression.ZipArchive]::new(
            $fileStream, [IO.Compression.ZipArchiveMode]::Read, $false,
            [Text.Encoding]::UTF8
        )
        $entries = @($archive.Entries)
        Assert-PostPublicationCondition `
            ($entries.Count -ge 2 -and $entries.Count -le 65) `
            'bundle archive has an invalid bounded entry count.'
        $entryNames = [Collections.Generic.HashSet[string]]::new(
            [StringComparer]::OrdinalIgnoreCase
        )
        $entryByName = [Collections.Generic.Dictionary[string, object]]::new(
            [StringComparer]::Ordinal
        )
        $totalLength = [long]0
        foreach ($entry in $entries) {
            $name = [string]$entry.FullName
            $unsafeComponent = @($name.Split('/') | Where-Object {
                $_.EndsWith('.', [StringComparison]::Ordinal) -or
                [regex]::IsMatch(
                    $_,
                    '^(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)',
                    [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
                        [Text.RegularExpressions.RegexOptions]::CultureInvariant
                )
            }).Count -ne 0
            $unixKind = ([int64]$entry.ExternalAttributes -shr 16) -band 0xF000
            Assert-PostPublicationCondition `
                ($name -cmatch '^(?:manifest\.json|MeAndAI\.QuickAdoption/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+)$' -and
                    -not $name.Contains('\') -and
                    -not $name.StartsWith('/') -and
                    $name -cnotmatch '(^|/)(?:\.|\.\.)(?:/|$)' -and
                    $name -cnotmatch '^[A-Za-z]:' -and
                    -not $unsafeComponent -and
                    $entryNames.Add($name) -and
                    $unixKind -in @(0, 0x8000)) `
                "bundle archive entry '$name' is unsafe, duplicated, or not one regular file."
            $totalLength += [long]$entry.Length
            Assert-PostPublicationCondition ($totalLength -le 67108864) `
                'bundle archive exceeds the bounded decompressed size limit.'
            $entryByName.Add($name, $entry)
        }
        Assert-PostPublicationCondition ($entryByName.ContainsKey('manifest.json')) `
            'bundle archive does not contain its canonical manifest.'

        $manifestBytes = Read-ZipEntryBytes -Entry $entryByName['manifest.json'] `
            -MaximumLength 1048576
        Assert-PostPublicationCondition `
            (-not ($manifestBytes.Length -ge 3 -and
                $manifestBytes[0] -eq 0xEF -and $manifestBytes[1] -eq 0xBB -and
                $manifestBytes[2] -eq 0xBF)) `
            'bundle manifest must be UTF-8 without a byte-order mark.'
        try {
            $manifestText = [Text.UTF8Encoding]::new($false, $true).GetString(
                $manifestBytes
            )
            $manifest = $manifestText | ConvertFrom-Json
        }
        catch {
            throw 'TEST-0065 bundle manifest is not strict UTF-8 JSON.'
        }
        $manifestProperties = @($manifest.PSObject.Properties | ForEach-Object {
            [string]$_.Name
        })
        Assert-PostPublicationCondition `
            (($manifestProperties -join ',') -ceq
                'schema,kind,runtimeRepository,runtimeReleaseTag,sourceCommit,entryPoint,minimumPowerShellVersion,payload') `
            'bundle manifest has an unsupported shape.'
        Assert-PostPublicationCondition `
            (($manifest.schema -is [int] -or $manifest.schema -is [long]) -and
                [long]$manifest.schema -eq 1 -and
                [string]$manifest.kind -ceq 'meandai.quick-adoption.module-bundle' -and
                [string]$manifest.runtimeRepository -ceq $Repository -and
                [string]$manifest.runtimeReleaseTag -ceq $Tag) `
            'bundle manifest identity does not match the immutable release.'
        Assert-PostPublicationCondition `
            ([string]$manifest.sourceCommit -ceq $ExpectedCommit) `
            'bundle manifest source commit does not match the immutable release commit.'
        Assert-PostPublicationCondition `
            ([string]$manifest.minimumPowerShellVersion -ceq '5.1') `
            'bundle manifest minimum PowerShell version is unsupported.'

        $payload = @($manifest.payload)
        Assert-PostPublicationCondition `
            ($payload.Count -ge 1 -and $payload.Count -le 64) `
            'bundle manifest payload inventory is empty or unbounded.'
        $payloadPaths = [Collections.Generic.List[string]]::new()
        $payloadSet = [Collections.Generic.HashSet[string]]::new(
            [StringComparer]::OrdinalIgnoreCase
        )
        $payloadByPath = [Collections.Generic.Dictionary[string, object]]::new(
            [StringComparer]::Ordinal
        )
        $payloadDeclaredLength = [long]0
        foreach ($payloadEntry in $payload) {
            $properties = @($payloadEntry.PSObject.Properties | ForEach-Object {
                [string]$_.Name
            })
            $path = [string]$payloadEntry.path
            Assert-PostPublicationCondition `
                (($properties -join ',') -ceq 'path,length,sha256' -and
                    $path -cmatch '^MeAndAI\.QuickAdoption/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+$' -and
                    $payloadSet.Add($path) -and
                    ($payloadEntry.length -is [int] -or $payloadEntry.length -is [long]) -and
                    [long]$payloadEntry.length -ge 0 -and
                    [string]$payloadEntry.sha256 -cmatch '^[0-9a-f]{64}$') `
                "bundle manifest payload entry '$path' is malformed or duplicated."
            Assert-PostPublicationCondition ($entryByName.ContainsKey($path)) `
                "bundle archive is missing manifest payload '$path'."
            $payloadDeclaredLength += [long]$payloadEntry.length
            Assert-PostPublicationCondition ($payloadDeclaredLength -le 67108864) `
                'bundle manifest payload exceeds the bounded decompressed size limit.'
            $bytes = Read-ZipEntryBytes -Entry $entryByName[$path] `
                -MaximumLength ([long]$payloadEntry.length)
            Assert-PostPublicationCondition `
                ($bytes.LongLength -eq [long]$payloadEntry.length -and
                    (Get-Sha256Hex -Bytes $bytes) -ceq [string]$payloadEntry.sha256) `
                "bundle payload '$path' does not match its manifest digest and length."
            $payloadPaths.Add($path)
            $payloadByPath.Add($path, $payloadEntry)
        }
        Assert-PostPublicationCondition `
            ($entryByName.Count -eq ($payload.Count + 1)) `
            'bundle archive contains entries outside its manifest payload inventory.'
        Assert-PostPublicationCondition `
            ([string]$manifest.entryPoint -cmatch
                '^MeAndAI\.QuickAdoption/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+\.psd1$' -and
                $payloadSet.Contains([string]$manifest.entryPoint)) `
            'bundle manifest entry point is absent from its payload inventory.'
        $expectedEntryOrder = @('manifest.json') + @($payloadPaths)
        $actualEntryOrder = @($entries | ForEach-Object { [string]$_.FullName })
        Assert-PostPublicationCondition `
            (($actualEntryOrder -join "`n") -ceq ($expectedEntryOrder -join "`n")) `
            'bundle archive entry order differs from its canonical manifest inventory.'

        $inventoryBytes = Get-GitHubContentBytes `
            -RepositoryPath $ExpectedBundleSourceInventoryPath
        try {
            $inventory = [Text.UTF8Encoding]::new($false, $true).GetString(
                $inventoryBytes
            ) | ConvertFrom-Json
        }
        catch {
            throw 'TEST-0065 released bundle source inventory is not strict UTF-8 JSON.'
        }
        $inventoryProperties = @($inventory.PSObject.Properties | ForEach-Object {
            [string]$_.Name
        })
        $inventorySources = @($inventory.sources | ForEach-Object { [string]$_ })
        Assert-PostPublicationCondition `
            (($inventoryProperties -join ',') -ceq 'schema,kind,entryPoint,sources' -and
                ($inventory.schema -is [int] -or $inventory.schema -is [long]) -and
                [long]$inventory.schema -eq 1 -and
                [string]$inventory.kind -ceq 'meandai.quick-adoption.bundle-sources' -and
                [string]$inventory.entryPoint -ceq [string]$manifest.entryPoint -and
                ($inventorySources -join "`n") -ceq (@($payloadPaths) -join "`n")) `
            'bundle manifest payload inventory does not match the released source inventory.'

        foreach ($path in $payloadPaths) {
            $repositoryPath = 'scripts/quick-adoption/' +
                $path.Substring('MeAndAI.QuickAdoption/'.Length)
            $sourceBytes = Get-GitHubContentBytes -RepositoryPath $repositoryPath
            $payloadEntry = $payloadByPath[$path]
            Assert-PostPublicationCondition `
                ($sourceBytes.LongLength -eq [long]$payloadEntry.length -and
                    (Get-Sha256Hex -Bytes $sourceBytes) -ceq [string]$payloadEntry.sha256) `
                "bundle payload '$path' does not match the released source commit."
        }
    }
    finally {
        if ($null -ne $archive) {
            $archive.Dispose()
        }
        $fileStream.Dispose()
    }
}

function Assert-ExpectedReleaseAssets {
    param([Parameter(Mandatory)][object]$Release)

    if ($expectedAssetNames.Count -eq 0) {
        return
    }
    $releaseAssets = @($Release.assets)
    Assert-PostPublicationCondition `
        ($releaseAssets.Count -eq $expectedAssetNames.Count) `
        'release does not contain the exact expected asset inventory.'
    $releaseAssetNames = @($releaseAssets | ForEach-Object { [string]$_.name })
    foreach ($name in $expectedAssetNames) {
        Assert-PostPublicationCondition `
            (@($releaseAssetNames | Where-Object { $_ -ceq $name }).Count -eq 1) `
            'release does not contain the exact expected asset inventory.'
    }

    $temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) `
        ('meandai-post-publication-' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $temporaryRoot)
    try {
        for ($index = 0; $index -lt $expectedAssetNames.Count; $index++) {
            $name = $expectedAssetNames[$index]
            $asset = @($releaseAssets | Where-Object {
                [string]$_.name -ceq $name
            })[0]
            $assetId = [string]$asset.id
            $assetDigest = [string]$asset.digest
            $assetUrl = [string]$asset.url
            $maximumAssetBytes = if ($name -ceq $ExpectedLauncherAssetName) {
                1048576
            }
            elseif ($name -ceq $ExpectedBundleAssetName) { 67108864 }
            else { 67108864 }
            Assert-PostPublicationCondition `
                ($asset.state -ceq 'uploaded' -and
                    $assetId -cmatch '^[1-9][0-9]*$' -and
                    ($asset.size -is [int] -or $asset.size -is [long]) -and
                    [long]$asset.size -gt 0 -and
                    [long]$asset.size -le $maximumAssetBytes -and
                    $assetDigest -cmatch '^sha256:[0-9a-f]{64}$' -and
                    $assetUrl -ceq "$repositoryApi/releases/assets/$assetId") `
                "release asset '$name' is missing canonical API digest, bounded size, or identity metadata."
            $downloadPath = Join-Path $temporaryRoot ("asset-$index.bin")
            $downloadHeaders = @{}
            foreach ($header in $headers.GetEnumerator()) {
                $downloadHeaders[$header.Key] = $header.Value
            }
            $downloadHeaders.Accept = 'application/octet-stream'
            Invoke-RestMethod -Method Get -Uri $assetUrl -Headers $downloadHeaders `
                -OutFile $downloadPath
            $downloadItem = Get-Item -LiteralPath $downloadPath -Force
            Assert-PostPublicationCondition `
                (-not $downloadItem.PSIsContainer -and
                    (($downloadItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) -and
                    [long]$downloadItem.Length -eq [long]$asset.size) `
                "release asset '$name' downloaded size does not match API metadata."
            $downloadDigest = (Get-FileHash -LiteralPath $downloadPath -Algorithm SHA256).Hash.ToLowerInvariant()
            Assert-PostPublicationCondition `
                ($downloadDigest -ceq $assetDigest.Substring('sha256:'.Length)) `
                "release asset '$name' downloaded digest does not match API metadata."
            if ($name -ceq $ExpectedLauncherAssetName) {
                $launcherSourceBytes = Get-GitHubContentBytes `
                    -RepositoryPath $ExpectedLauncherSourcePath
                Assert-PostPublicationCondition `
                    ($launcherSourceBytes.LongLength -eq $downloadItem.Length -and
                        (Get-Sha256Hex -Bytes $launcherSourceBytes) -ceq $downloadDigest) `
                    "release launcher asset '$name' does not match its released source commit."
            }
            elseif ($name -ceq $ExpectedBundleAssetName) {
                Assert-QuickAdoptionBundle -BundlePath $downloadPath
            }
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryRoot) {
            Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
        }
    }
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

# Keep the larger asset downloads last so inexpensive metadata and governance
# failures stop before consuming release bandwidth.
Assert-ExpectedReleaseAssets -Release $release

Write-Host "TEST-0065 post-publication evidence verified for $Repository $Tag at $ExpectedCommit." `
    -ForegroundColor Green
