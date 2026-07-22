[CmdletBinding()]
param(
    [string]$TargetPath = '.',
    [string]$Owner = '',
    [string]$RepositoryName = '',
    [ValidateSet('private', 'public', 'internal')]
    [string]$Visibility = 'private',
    [string]$ProtocolRepository = 'hasanmanzak/meAndAI',
    [string]$ProtocolTag = 'v0.13.0',
    [string]$RemoteName = 'origin',
    [ValidateRange(1, 60)]
    [int]$WorkflowTimeoutMinutes = 15,
    [ValidateRange(1, 120)]
    [int]$CodexTimeoutMinutes = 30,
    [ValidateRange(0, 7200)]
    [int]$CodexTimeoutSeconds = 0,
    [ValidateSet('Auto', 'FreshAdoption', 'FullMigration', 'HybridReconciliation', 'CleanStart', 'Abort')]
    [string]$AdoptionStrategy = 'Auto',
    [switch]$NonInteractive,
    [switch]$AcknowledgeProtocolRecordLoss,
    [switch]$SkipLifecycleDispatch,
    [Alias('SkipCodexDelegation')]
    [switch]$SkipLocalCodex,
    [switch]$NoProgress,
    [string]$CodexCommand = '',
    [string]$TemporaryCodexVersion = '0.144.4'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$runtimeRepository = 'hasanmanzak/meAndAI'
$runtimeReleaseTag = 'v0.13.0'
$runtimeBundleAssetName = 'MeAndAI.QuickAdoption.Bundle.zip'
$runtimeBundleManifestName = 'manifest.json'
$runtimeBundleManifestKind = 'meandai.quick-adoption.module-bundle'
$runtimeBundleMaximumEntryCount = 64
$runtimeBundleMaximumArchiveBytes = 67108864
$runtimeBundleMaximumExpandedBytes = 67108864
$runtimeGitHubApiVersion = '2026-03-10'
$runtimeMinimumGitHubCliVersion = '2.82.1'

function Invoke-QuickAdoptionBootstrapNative {
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string[]]$Arguments,
        [int[]]$AcceptedExitCodes = @(0),
        [switch]$PassThruResult
    )

    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $global:LASTEXITCODE = 0
        $output = @(& $Command @Arguments 2>&1)
        $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($AcceptedExitCodes -notcontains $exitCode) {
        throw "$Command $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    $textOutput = @($output | ForEach-Object { [string]$_ })
    if ($PassThruResult) {
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output = $textOutput
        }
    }
    return $textOutput
}

function Invoke-QuickAdoptionBootstrapGitHubJson {
    param([Parameter(Mandatory)][string]$Endpoint)

    $text = @(Invoke-QuickAdoptionBootstrapNative -Command 'gh' -Arguments @(
        'api',
        '-H', 'Accept: application/vnd.github+json',
        '-H', "X-GitHub-Api-Version: $runtimeGitHubApiVersion",
        $Endpoint
    )) -join [Environment]::NewLine
    if ([string]::IsNullOrWhiteSpace($text)) {
        throw "GitHub returned no JSON evidence for '$Endpoint'."
    }
    try { return $text | ConvertFrom-Json }
    catch { throw "GitHub returned invalid JSON evidence for '$Endpoint'." }
}

function Compare-QuickAdoptionBootstrapDecimalComponent {
    param(
        [Parameter(Mandatory)][string]$Left,
        [Parameter(Mandatory)][string]$Right
    )
    if ($Left.Length -ne $Right.Length) {
        return [Math]::Sign($Left.Length - $Right.Length)
    }
    return [Math]::Sign([string]::CompareOrdinal($Left, $Right))
}

function Assert-QuickAdoptionBootstrapGitHubCliVersion {
    $output = @(Invoke-QuickAdoptionBootstrapNative -Command 'gh' `
        -Arguments @('--version'))
    $pattern = '\Agh version (?<major>0|[1-9][0-9]*)\.(?<minor>0|[1-9][0-9]*)\.(?<revision>0|[1-9][0-9]*)(?: \([^()\r\n]+\))?\z'
    $versions = @($output | ForEach-Object {
        $match = [regex]::Match(
            [string]$_, $pattern,
            [Text.RegularExpressions.RegexOptions]::CultureInvariant
        )
        if ($match.Success) {
            [pscustomobject]@{
                Text = "$($match.Groups['major'].Value).$($match.Groups['minor'].Value).$($match.Groups['revision'].Value)"
                Parts = @(
                    $match.Groups['major'].Value,
                    $match.Groups['minor'].Value,
                    $match.Groups['revision'].Value
                )
            }
        }
    })
    if ($versions.Count -ne 1) {
        throw "Unable to determine one canonical GitHub CLI version; $runtimeMinimumGitHubCliVersion or newer is required."
    }
    $minimum = @($runtimeMinimumGitHubCliVersion.Split('.'))
    for ($index = 0; $index -lt $minimum.Count; $index++) {
        $comparison = Compare-QuickAdoptionBootstrapDecimalComponent `
            -Left ([string]$versions[0].Parts[$index]) `
            -Right ([string]$minimum[$index])
        if ($comparison -lt 0) {
            throw "GitHub CLI $runtimeMinimumGitHubCliVersion or newer is required; detected $($versions[0].Text)."
        }
        if ($comparison -gt 0) { break }
    }
}

function Assert-QuickAdoptionBootstrapGitHubAuthentication {
    [void](Invoke-QuickAdoptionBootstrapNative -Command 'gh' `
        -Arguments @('auth', 'status'))
}

function Get-QuickAdoptionBootstrapSha256 {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($algorithm.ComputeHash($Bytes)) `
            -replace '-', '').ToLowerInvariant()
    }
    finally { $algorithm.Dispose() }
}

function Get-QuickAdoptionBootstrapFileEvidence {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][long]$MaximumBytes
    )

    $stream = [IO.File]::Open(
        $Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read
    )
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $buffer = [byte[]]::new(81920)
        [long]$total = 0
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            if ($total -gt ($MaximumBytes - $read)) {
                throw 'Downloaded runtime bundle exceeds its maximum byte length.'
            }
            [void]$algorithm.TransformBlock($buffer, 0, $read, $buffer, 0)
            $total += $read
        }
        [void]$algorithm.TransformFinalBlock([byte[]]::new(0), 0, 0)
        return [pscustomobject]@{
            Length = $total
            Sha256 = ([BitConverter]::ToString($algorithm.Hash) `
                -replace '-', '').ToLowerInvariant()
        }
    }
    finally {
        $algorithm.Dispose()
        $stream.Dispose()
    }
}

function Assert-QuickAdoptionBootstrapRegularFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Label
    )

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($item.PSIsContainer -or
        (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
        throw "$Label is not one regular non-reparse file."
    }
    return $item
}

function Get-QuickAdoptionBootstrapPathComparison {
    if ($env:OS -eq 'Windows_NT') {
        return [StringComparison]::OrdinalIgnoreCase
    }
    return [StringComparison]::Ordinal
}

function Assert-QuickAdoptionBootstrapNoReparseAncestor {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Label
    )

    $current = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    while ($null -ne $current) {
        if (($current.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "$Label crosses a linked or reparse ancestor: $($current.FullName)"
        }
        $parentPath = Split-Path -Parent $current.FullName
        if ([string]::IsNullOrEmpty($parentPath) -or
            $parentPath -ceq $current.FullName) {
            break
        }
        $parent = Get-Item -LiteralPath $parentPath -Force -ErrorAction Stop
        if ($parent.FullName -ceq $current.FullName) { break }
        $current = $parent
    }
}

function Get-QuickAdoptionBootstrapTargetRoot {
    $fullPath = [IO.Path]::GetFullPath($TargetPath)
    $item = Get-Item -LiteralPath $fullPath -Force -ErrorAction Stop
    if (-not $item.PSIsContainer -or
        (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
        throw 'TargetPath must be one existing regular directory.'
    }
    Assert-QuickAdoptionBootstrapNoReparseAncestor -Path $item.FullName `
        -Label 'TargetPath'
    return $item.FullName
}

function Get-QuickAdoptionBootstrapTemporaryRoot {
    param([Parameter(Mandatory)][string]$ConsumerRoot)

    $temporaryBase = Get-Item -LiteralPath ([IO.Path]::GetTempPath()) `
        -Force -ErrorAction Stop
    if (-not $temporaryBase.PSIsContainer) {
        throw 'The process temporary path is not one directory.'
    }
    Assert-QuickAdoptionBootstrapNoReparseAncestor -Path $temporaryBase.FullName `
        -Label 'The process temporary path'
    $candidate = [IO.Path]::GetFullPath((Join-Path $temporaryBase.FullName `
        ('meandai-quick-adoption-runtime-' + [guid]::NewGuid().ToString('N'))))
    $consumer = [IO.Path]::GetFullPath($ConsumerRoot).TrimEnd(
        [char[]]@(
            [IO.Path]::DirectorySeparatorChar,
            [IO.Path]::AltDirectorySeparatorChar
        )
    )
    $consumerPrefix = $consumer + [IO.Path]::DirectorySeparatorChar
    $comparison = Get-QuickAdoptionBootstrapPathComparison
    if ($candidate.Equals($consumer, $comparison) -or
        $candidate.StartsWith($consumerPrefix, $comparison)) {
        throw 'Quick-adoption runtime storage must remain outside the consumer repository.'
    }
    return $candidate
}

function Assert-QuickAdoptionBootstrapProtocolTokenLocal {
    param([Parameter(Mandatory)][string]$Root)

    $gitMarker = Join-Path $Root '.git'
    $inside = Invoke-QuickAdoptionBootstrapNative -Command 'git' -Arguments @(
        '-C', $Root, 'rev-parse', '--is-inside-work-tree'
    ) -AcceptedExitCodes @(0, 128) -PassThruResult
    if ($inside.ExitCode -ne 0) {
        if (Test-Path -LiteralPath $gitMarker) {
            throw 'The local Git repository identity could not be verified before reading the protocol token.'
        }
        return
    }
    if ((@($inside.Output) -join '').Trim() -cne 'true') {
        throw 'The protocol-token target is not one Git working tree.'
    }
    $gitRootResult = Invoke-QuickAdoptionBootstrapNative -Command 'git' `
        -Arguments @('-C', $Root, 'rev-parse', '--show-toplevel')
    $gitRoot = [IO.Path]::GetFullPath((@($gitRootResult) -join '').Trim())
    $comparison = if ($env:OS -eq 'Windows_NT') {
        [StringComparison]::OrdinalIgnoreCase
    }
    else { [StringComparison]::Ordinal }
    if (-not $gitRoot.Equals([IO.Path]::GetFullPath($Root), $comparison)) {
        throw 'TargetPath is nested inside another Git repository; select its root explicitly.'
    }
    $shallowResult = Invoke-QuickAdoptionBootstrapNative -Command 'git' `
        -Arguments @('-C', $Root, 'rev-parse', '--is-shallow-repository')
    $shallow = ((@($shallowResult) -join '').Trim())
    if ($shallow -cnotin @('true', 'false')) {
        throw 'Protocol-token history completeness could not be determined.'
    }
    if ($shallow -ceq 'true') {
        throw 'Protocol-token history validation requires a non-shallow repository.'
    }
    $pathspec = ':(icase,glob)**/MEANDAI_RO_FG_PAT.txt'
    $tracked = Invoke-QuickAdoptionBootstrapNative -Command 'git' -Arguments @(
        '-C', $Root, 'ls-files', '--error-unmatch', '--', $pathspec
    ) -AcceptedExitCodes @(0, 1) -PassThruResult
    if ($tracked.ExitCode -eq 0) {
        throw 'Credential-shaped file MEANDAI_RO_FG_PAT.txt is tracked or staged; rotate it before reuse.'
    }
    $history = Invoke-QuickAdoptionBootstrapNative -Command 'git' -Arguments @(
        '-C', $Root, 'log', '--all', '--reflog', '--format=%H', '--', $pathspec
    ) -PassThruResult
    if ((@($history.Output) -join '').Trim()) {
        throw 'Credential-shaped file MEANDAI_RO_FG_PAT.txt appears in reachable history; rotate it before reuse.'
    }
}

function Read-QuickAdoptionBootstrapProtocolToken {
    param([Parameter(Mandatory)][string]$Root)

    $path = Join-Path $Root 'MEANDAI_RO_FG_PAT.txt'
    if (-not (Test-Path -LiteralPath $path)) { return '' }
    [void](Get-Command git -CommandType Application -ErrorAction Stop)
    Assert-QuickAdoptionBootstrapProtocolTokenLocal -Root $Root
    $item = Assert-QuickAdoptionBootstrapRegularFile -Path $path `
        -Label 'Protocol read credential'
    if ($item.Name -cne 'MEANDAI_RO_FG_PAT.txt') {
        throw 'Protocol read credential must use its exact canonical root name.'
    }
    $value = [IO.File]::ReadAllText($item.FullName).Trim()
    $confirmed = Assert-QuickAdoptionBootstrapRegularFile -Path $path `
        -Label 'Protocol read credential'
    if ($confirmed.FullName -cne $item.FullName -or
        [string]::IsNullOrEmpty($value) -or $value -match '\s') {
        throw 'Protocol read credential must remain one exact non-whitespace token file.'
    }
    return $value
}

function Get-QuickAdoptionBootstrapRuntimeEvidence {
    $release = Invoke-QuickAdoptionBootstrapGitHubJson -Endpoint (
        "repos/$runtimeRepository/releases/tags/$runtimeReleaseTag"
    )
    foreach ($name in @(
        'tag_name', 'draft', 'prerelease', 'immutable', 'published_at', 'assets'
    )) {
        if ($null -eq $release.PSObject.Properties[$name]) {
            throw "Runtime release evidence is missing '$name'."
        }
    }
    if ([string]$release.tag_name -cne $runtimeReleaseTag -or
        $release.draft -isnot [bool] -or [bool]$release.draft -or
        $release.prerelease -isnot [bool] -or [bool]$release.prerelease -or
        $release.immutable -isnot [bool] -or -not [bool]$release.immutable -or
        [string]::IsNullOrWhiteSpace([string]$release.published_at)) {
        throw "Quick-adoption runtime '$runtimeReleaseTag' is not one exact published immutable GitHub Release."
    }
    $assets = @($release.assets | Where-Object {
        [string]$_.name -ceq $runtimeBundleAssetName
    })
    if ($assets.Count -ne 1) {
        throw "Runtime release must contain exactly one '$runtimeBundleAssetName' asset."
    }
    $asset = $assets[0]
    if ($null -eq $asset.PSObject.Properties['digest'] -or
        [string]$asset.digest -cnotmatch '^sha256:[0-9a-f]{64}$' -or
        $null -eq $asset.PSObject.Properties['size'] -or
        [long]$asset.size -le 0) {
        throw 'Runtime bundle asset lacks canonical digest or length evidence.'
    }
    if ([long]$asset.size -gt $runtimeBundleMaximumArchiveBytes) {
        throw 'Runtime bundle asset exceeds its maximum byte length.'
    }

    $reference = Invoke-QuickAdoptionBootstrapGitHubJson -Endpoint (
        "repos/$runtimeRepository/git/ref/tags/$runtimeReleaseTag"
    )
    if ($null -eq $reference.PSObject.Properties['object'] -or
        $null -eq $reference.object -or
        [string]$reference.object.sha -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Runtime release tag reference is incomplete.'
    }
    $objectType = [string]$reference.object.type
    $sourceCommit = [string]$reference.object.sha
    if ($objectType -ceq 'tag') {
        $tagObject = Invoke-QuickAdoptionBootstrapGitHubJson -Endpoint (
            "repos/$runtimeRepository/git/tags/$sourceCommit"
        )
        if ($null -eq $tagObject.PSObject.Properties['object'] -or
            $null -eq $tagObject.object -or
            [string]$tagObject.object.type -cne 'commit' -or
            [string]$tagObject.object.sha -cnotmatch '^[0-9a-f]{40}$') {
            throw 'Runtime annotated tag does not resolve directly to one commit.'
        }
        $sourceCommit = [string]$tagObject.object.sha
    }
    elseif ($objectType -cne 'commit') {
        throw 'Runtime release tag does not resolve to a Git commit.'
    }

    return [pscustomobject]@{
        SourceCommit = $sourceCommit
        AssetLength = [long]$asset.size
        AssetSha256 = ([string]$asset.digest).Substring('sha256:'.Length)
    }
}

function Read-QuickAdoptionBootstrapZipEntry {
    param(
        [Parameter(Mandatory)]$Entry,
        [Parameter(Mandatory)][long]$MaximumBytes
    )

    $stream = $Entry.Open()
    $memory = [IO.MemoryStream]::new()
    try {
        $buffer = [byte[]]::new(81920)
        [long]$total = 0
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            if ($total -gt ($MaximumBytes - $read)) {
                throw "Runtime bundle entry '$($Entry.FullName)' exceeds its expanded-size limit."
            }
            $memory.Write($buffer, 0, $read)
            $total += $read
        }
        return ,$memory.ToArray()
    }
    finally {
        $memory.Dispose()
        $stream.Dispose()
    }
}

function Get-QuickAdoptionBootstrapBundle {
    param(
        [Parameter(Mandatory)][string]$ArchivePath,
        [Parameter(Mandatory)][string]$ExtractionRoot,
        [Parameter(Mandatory)][string]$ExpectedSourceCommit
    )

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        $entries = @($archive.Entries)
        if ($entries.Count -lt 2 -or
            $entries.Count -gt $runtimeBundleMaximumEntryCount) {
            throw 'Runtime bundle has an invalid bounded entry count.'
        }
        $entryByPath = [Collections.Generic.Dictionary[string, object]]::new(
            [StringComparer]::Ordinal
        )
        $caseInventory = [Collections.Generic.HashSet[string]]::new(
            [StringComparer]::OrdinalIgnoreCase
        )
        [long]$expandedBytes = 0
        foreach ($entry in $entries) {
            $path = [string]$entry.FullName
            $unsafeComponent = @($path.Split('/') | Where-Object {
                $_.EndsWith('.', [StringComparison]::Ordinal) -or
                [regex]::IsMatch(
                    $_,
                    '^(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)',
                    [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
                        [Text.RegularExpressions.RegexOptions]::CultureInvariant
                )
            }).Count -ne 0
            if ($path.Contains('\') -or $path.StartsWith('/') -or
                $path -match '(^|/)(?:\.|\.\.)(?:/|$)' -or
                $path -match '^[A-Za-z]:' -or
                $path -cnotmatch '^(?:manifest\.json|MeAndAI\.QuickAdoption/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+)$' -or
                $unsafeComponent -or
                -not $caseInventory.Add($path) -or
                $entryByPath.ContainsKey($path)) {
                throw "Runtime bundle entry '$path' is unsafe or duplicated."
            }
            $unixKind = ([int64]$entry.ExternalAttributes -shr 16) -band 0xF000
            if ($unixKind -ne 0 -and $unixKind -ne 0x8000) {
                throw "Runtime bundle entry '$path' is not a regular file."
            }
            $entryLength = [long]$entry.Length
            if ($entryLength -lt 0 -or
                $entryLength -gt ($runtimeBundleMaximumExpandedBytes - $expandedBytes)) {
                throw 'Runtime bundle exceeds the expanded-size limit.'
            }
            $expandedBytes += $entryLength
            $entryByPath.Add($path, $entry)
        }
        if (-not $entryByPath.ContainsKey($runtimeBundleManifestName)) {
            throw 'Runtime bundle manifest is missing.'
        }
        $manifestBytes = Read-QuickAdoptionBootstrapZipEntry `
            -Entry $entryByPath[$runtimeBundleManifestName] -MaximumBytes 1048576
        [long]$actualExpandedBytes = [long]$manifestBytes.LongLength
        if ($manifestBytes.Length -ge 3 -and
            $manifestBytes[0] -eq 0xEF -and $manifestBytes[1] -eq 0xBB -and
            $manifestBytes[2] -eq 0xBF) {
            throw 'Runtime bundle manifest must be UTF-8 without a BOM.'
        }
        try {
            $manifest = [Text.UTF8Encoding]::new($false, $true).GetString(
                $manifestBytes
            ) | ConvertFrom-Json
        }
        catch { throw 'Runtime bundle manifest is not strict UTF-8 JSON.' }
        $manifestNames = @($manifest.PSObject.Properties | ForEach-Object {
            [string]$_.Name
        })
        if (($manifestNames -join ',') -cne (
                'schema,kind,runtimeRepository,runtimeReleaseTag,sourceCommit,' +
                'entryPoint,minimumPowerShellVersion,payload'
            ) -or
            ($manifest.schema -isnot [int] -and $manifest.schema -isnot [long]) -or
            [long]$manifest.schema -ne 1 -or
            $manifest.kind -isnot [string] -or
            $manifest.runtimeRepository -isnot [string] -or
            $manifest.runtimeReleaseTag -isnot [string] -or
            $manifest.sourceCommit -isnot [string] -or
            $manifest.entryPoint -isnot [string] -or
            $manifest.minimumPowerShellVersion -isnot [string] -or
            [string]$manifest.kind -cne $runtimeBundleManifestKind -or
            [string]$manifest.runtimeRepository -cne $runtimeRepository -or
            [string]$manifest.runtimeReleaseTag -cne $runtimeReleaseTag -or
            [string]$manifest.sourceCommit -cne $ExpectedSourceCommit -or
            [string]$manifest.minimumPowerShellVersion -cne '5.1') {
            throw 'Runtime bundle manifest identity does not match its immutable release.'
        }
        $payload = @($manifest.payload)
        if ($payload.Count -ne ($entries.Count - 1) -or $payload.Count -lt 1) {
            throw 'Runtime bundle payload inventory is incomplete or oversized.'
        }
        $payloadBytes = [Collections.Generic.Dictionary[string, byte[]]]::new(
            [StringComparer]::Ordinal
        )
        foreach ($file in $payload) {
            $fileNames = @($file.PSObject.Properties | ForEach-Object {
                [string]$_.Name
            })
            $path = [string]$file.path
            if (($fileNames -join ',') -cne 'path,length,sha256' -or
                $file.path -isnot [string] -or
                ($file.length -isnot [int] -and $file.length -isnot [long]) -or
                $file.sha256 -isnot [string] -or
                $path -cnotmatch '^MeAndAI\.QuickAdoption/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+$' -or
                [string]$file.sha256 -cnotmatch '^[0-9a-f]{64}$' -or
                [long]$file.length -lt 0 -or
                -not $entryByPath.ContainsKey($path) -or
                $payloadBytes.ContainsKey($path)) {
                throw "Runtime bundle payload record '$path' is invalid."
            }
            $remainingExpandedBytes = $runtimeBundleMaximumExpandedBytes -
                $actualExpandedBytes
            if ([long]$file.length -gt $remainingExpandedBytes) {
                throw 'Runtime bundle exceeds the expanded-size limit.'
            }
            $bytes = Read-QuickAdoptionBootstrapZipEntry `
                -Entry $entryByPath[$path] -MaximumBytes ([long]$file.length)
            if ([long]$bytes.LongLength -ne [long]$file.length -or
                (Get-QuickAdoptionBootstrapSha256 -Bytes $bytes) -cne
                    [string]$file.sha256) {
                throw "Runtime bundle payload '$path' failed length or digest verification."
            }
            $actualExpandedBytes += [long]$bytes.LongLength
            $payloadBytes.Add($path, $bytes)
        }
        if ([string]$manifest.entryPoint -cnotmatch '^MeAndAI\.QuickAdoption/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+\.psd1$' -or
            -not $payloadBytes.ContainsKey([string]$manifest.entryPoint)) {
            throw 'Runtime bundle entry point is invalid or absent.'
        }
        $expectedPaths = @($runtimeBundleManifestName) + @($payload |
            ForEach-Object { [string]$_.path })
        $actualPaths = @($entries | ForEach-Object { [string]$_.FullName })
        if (($expectedPaths -join "`n") -cne ($actualPaths -join "`n")) {
            throw 'Runtime bundle contains an unexpected or out-of-order entry.'
        }

        if (Test-Path -LiteralPath $ExtractionRoot) {
            throw 'Runtime bundle extraction root already exists.'
        }
        $rootPrefix = [IO.Path]::GetFullPath($ExtractionRoot).TrimEnd(
            [char[]]@([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        ) + [IO.Path]::DirectorySeparatorChar
        $comparison = Get-QuickAdoptionBootstrapPathComparison
        $destinationComparer = if ($env:OS -eq 'Windows_NT') {
            [StringComparer]::OrdinalIgnoreCase
        }
        else { [StringComparer]::Ordinal }
        $destinations = [Collections.Generic.Dictionary[string, string]]::new(
            [StringComparer]::Ordinal
        )
        $canonicalDestinations = [Collections.Generic.HashSet[string]]::new(
            $destinationComparer
        )
        foreach ($path in @($payload | ForEach-Object { [string]$_.path })) {
            $destination = [IO.Path]::GetFullPath((Join-Path $ExtractionRoot `
                ($path -replace '/', [IO.Path]::DirectorySeparatorChar)))
            if (-not $destination.StartsWith($rootPrefix, $comparison) -or
                -not $canonicalDestinations.Add($destination)) {
                throw "Runtime bundle destination '$path' escaped its extraction root."
            }
            $destinations.Add($path, $destination)
        }
        [void](New-Item -ItemType Directory -Path $ExtractionRoot)
        foreach ($path in @($payload | ForEach-Object { [string]$_.path })) {
            $destination = $destinations[$path]
            $parent = Split-Path -Parent $destination
            if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
                [void](New-Item -ItemType Directory -Path $parent -Force)
            }
            $destinationStream = [IO.File]::Open(
                $destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write,
                [IO.FileShare]::None
            )
            try {
                $bytes = [byte[]]$payloadBytes[$path]
                $destinationStream.Write($bytes, 0, $bytes.Length)
            }
            finally { $destinationStream.Dispose() }
            [void](Assert-QuickAdoptionBootstrapRegularFile -Path $destination `
                -Label "Runtime module '$path'")
            $written = Get-QuickAdoptionBootstrapFileEvidence `
                -Path $destination -MaximumBytes ([long]$payloadBytes[$path].LongLength)
            if ([long]$written.Length -ne [long]$payloadBytes[$path].LongLength -or
                [string]$written.Sha256 -cne
                    (Get-QuickAdoptionBootstrapSha256 -Bytes $payloadBytes[$path])) {
                throw "Runtime module '$path' changed during extraction."
            }
        }
        return Join-Path $ExtractionRoot `
            (([string]$manifest.entryPoint) -replace '/', [IO.Path]::DirectorySeparatorChar)
    }
    finally { $archive.Dispose() }
}

if ($PSVersionTable.PSVersion -lt [version]'5.1') {
    throw 'Quick adoption requires PowerShell 5.1 or newer.'
}
$targetRoot = Get-QuickAdoptionBootstrapTargetRoot
if ($AdoptionStrategy -ceq 'Abort') {
    Write-Host 'Initial adoption was aborted before runtime download or repository mutation.'
    return
}
$gh = @(Get-Command gh -CommandType Application -ErrorAction Stop | Select-Object -First 1)
if ($gh.Count -ne 1) {
    throw 'GitHub CLI is required to verify and download the quick-adoption runtime.'
}
[void](Assert-QuickAdoptionBootstrapGitHubCliVersion)
$protocolToken = Read-QuickAdoptionBootstrapProtocolToken -Root $targetRoot

$temporaryRoot = Get-QuickAdoptionBootstrapTemporaryRoot -ConsumerRoot $targetRoot
$module = $null
try {
    [void](New-Item -ItemType Directory -Path $temporaryRoot)
    $previousGitHubToken = [Environment]::GetEnvironmentVariable(
        'GH_TOKEN', 'Process'
    )
    $previousGitHubHost = [Environment]::GetEnvironmentVariable(
        'GH_HOST', 'Process'
    )
    try {
        [Environment]::SetEnvironmentVariable(
            'GH_HOST', 'github.com', 'Process'
        )
        if (-not [string]::IsNullOrEmpty($protocolToken)) {
            [Environment]::SetEnvironmentVariable(
                'GH_TOKEN', $protocolToken, 'Process'
            )
        }
        Assert-QuickAdoptionBootstrapGitHubAuthentication
        $evidence = Get-QuickAdoptionBootstrapRuntimeEvidence
        $downloadRoot = Join-Path $temporaryRoot 'download'
        [void](New-Item -ItemType Directory -Path $downloadRoot)
        [void](Invoke-QuickAdoptionBootstrapNative -Command 'gh' -Arguments @(
            'release', 'download', $runtimeReleaseTag,
            '--repo', $runtimeRepository,
            '--pattern', $runtimeBundleAssetName,
            '--dir', $downloadRoot
        ))
    }
    finally {
        [Environment]::SetEnvironmentVariable(
            'GH_TOKEN', $previousGitHubToken, 'Process'
        )
        [Environment]::SetEnvironmentVariable(
            'GH_HOST', $previousGitHubHost, 'Process'
        )
        $protocolToken = ''
    }
    $archivePath = Join-Path $downloadRoot $runtimeBundleAssetName
    $archiveItem = Assert-QuickAdoptionBootstrapRegularFile -Path $archivePath `
        -Label 'Downloaded runtime bundle'
    $archiveEvidence = Get-QuickAdoptionBootstrapFileEvidence `
        -Path $archiveItem.FullName -MaximumBytes $runtimeBundleMaximumArchiveBytes
    if ([long]$archiveEvidence.Length -ne [long]$evidence.AssetLength -or
        [string]$archiveEvidence.Sha256 -cne [string]$evidence.AssetSha256) {
        throw 'Downloaded runtime bundle does not match its immutable release digest.'
    }
    $moduleManifestPath = Get-QuickAdoptionBootstrapBundle `
        -ArchivePath $archiveItem.FullName `
        -ExtractionRoot (Join-Path $temporaryRoot 'runtime') `
        -ExpectedSourceCommit ([string]$evidence.SourceCommit)
    $module = Import-Module -Name $moduleManifestPath -Force -PassThru
    $exports = @($module.ExportedCommands.Keys)
    if ($exports.Count -ne 1 -or
        [string]$exports[0] -cne 'Invoke-MeAndAIQuickAdoption') {
        throw 'Verified runtime module exports an unexpected command surface.'
    }
    $entryCommand = Get-Command -Name 'Invoke-MeAndAIQuickAdoption' `
        -Module $module.Name -CommandType Function -ErrorAction Stop
    & $entryCommand @PSBoundParameters
}
finally {
    if ($null -ne $module) { Remove-Module -ModuleInfo $module -Force }
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
