[CmdletBinding()]
param(
    [string]$SourceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [Parameter(Mandatory)][string]$RuntimeReleaseTag,
    [Parameter(Mandatory)][string]$SourceCommit,
    [Parameter(Mandatory)][string]$OutputPath,
    [string]$RuntimeRepository = 'hasanmanzak/meAndAI'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$maximumBundleSourceBytes = 67108864

function Invoke-BundleGitText {
    param(
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $global:LASTEXITCODE = 0
        $output = @(& $script:BundleGitCommand -C $WorkingDirectory @Arguments 2>&1)
        $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
    }
    finally { $ErrorActionPreference = $previousPreference }
    if ($exitCode -ne 0) {
        throw "git $($Arguments -join ' ') failed: $(@($output) -join [Environment]::NewLine)"
    }
    return @($output | ForEach-Object { [string]$_ })
}

function Read-BundleGitBlob {
    param(
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$Commit,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][long]$MaximumBytes
    )

    if ($RelativePath -cnotmatch '^(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+$') {
        throw "Tracked bundle path '$RelativePath' is unsafe."
    }
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $script:BundleGitCommand
    $startInfo.Arguments = "cat-file blob $Commit`:$RelativePath"
    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $memory = [IO.MemoryStream]::new()
    $started = $false
    try {
        if (-not $process.Start()) {
            throw "Unable to read tracked bundle source '$RelativePath'."
        }
        $started = $true
        $buffer = [byte[]]::new(81920)
        [long]$total = 0
        while (($read = $process.StandardOutput.BaseStream.Read(
            $buffer, 0, $buffer.Length
        )) -gt 0) {
            if ($total -gt ($MaximumBytes - $read)) {
                throw "Tracked bundle source '$RelativePath' exceeds its size limit."
            }
            $memory.Write($buffer, 0, $read)
            $total += $read
        }
        $errorText = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            throw "Unable to read tracked bundle source '$RelativePath': $errorText"
        }
        return ,$memory.ToArray()
    }
    finally {
        if ($started -and -not $process.HasExited) { $process.Kill() }
        $memory.Dispose()
        $process.Dispose()
    }
}

if ($RuntimeRepository -cnotmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
    throw 'RuntimeRepository must be one canonical owner/name identity.'
}
if ($RuntimeReleaseTag -cnotmatch '^v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)$') {
    throw 'RuntimeReleaseTag must be one canonical release tag.'
}
if ($SourceCommit -cnotmatch '^[0-9a-f]{40}$') {
    throw 'SourceCommit must be one full lowercase Git commit SHA.'
}

$script:BundleGitCommand = (Get-Command git -CommandType Application `
    -ErrorAction Stop | Select-Object -First 1).Source
$sourceRootItem = Get-Item -LiteralPath (Resolve-Path -LiteralPath $SourceRoot).Path `
    -Force -ErrorAction Stop
if (-not $sourceRootItem.PSIsContainer -or
    (($sourceRootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
    throw 'SourceRoot must be one regular non-reparse directory.'
}
$resolvedSourceRoot = $sourceRootItem.FullName
$gitRoot = ((Invoke-BundleGitText -WorkingDirectory $resolvedSourceRoot `
    -Arguments @('rev-parse', '--show-toplevel')) -join '').Trim()
$pathComparison = if ($env:OS -eq 'Windows_NT') {
    [StringComparison]::OrdinalIgnoreCase
}
else { [StringComparison]::Ordinal }
if (-not ([IO.Path]::GetFullPath($gitRoot)).Equals(
    [IO.Path]::GetFullPath($resolvedSourceRoot), $pathComparison
)) {
    throw 'SourceRoot must be the exact Git working-tree root.'
}
$headCommit = ((Invoke-BundleGitText -WorkingDirectory $resolvedSourceRoot `
    -Arguments @('rev-parse', 'HEAD')) -join '').Trim()
if ($headCommit -cne $SourceCommit) {
    throw 'SourceCommit must equal the exact checked-out HEAD commit.'
}
$sourceStatus = @(Invoke-BundleGitText -WorkingDirectory $resolvedSourceRoot `
    -Arguments @('status', '--porcelain=v1', '--untracked-files=all'))
if (($sourceStatus -join '').Length -ne 0) {
    throw 'Bundle construction requires one clean tracked source tree.'
}

$inventoryRelativePath = 'scripts/quick-adoption/bundle.sources.json'
$inventoryPath = Join-Path $resolvedSourceRoot `
    $inventoryRelativePath
$inventoryItem = Get-Item -LiteralPath $inventoryPath -Force -ErrorAction Stop
if ($inventoryItem.PSIsContainer -or
    (($inventoryItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
    throw 'Bundle source inventory must be one regular file.'
}
$inventoryStage = @(Invoke-BundleGitText -WorkingDirectory $resolvedSourceRoot `
    -Arguments @('ls-files', '--stage', '--error-unmatch', '--', $inventoryRelativePath))
if ($inventoryStage.Count -ne 1 -or
    [string]$inventoryStage[0] -cnotmatch '^100(?:644|755) [0-9a-f]{40} 0\t') {
    throw 'Bundle source inventory is not one exact tracked regular Git blob.'
}
$inventoryBytes = Read-BundleGitBlob -WorkingDirectory $resolvedSourceRoot `
    -Commit $SourceCommit -RelativePath $inventoryRelativePath -MaximumBytes 1048576
if ($inventoryBytes.Length -ge 3 -and $inventoryBytes[0] -eq 0xEF -and
    $inventoryBytes[1] -eq 0xBB -and $inventoryBytes[2] -eq 0xBF) {
    throw 'Bundle source inventory must be strict UTF-8 without a BOM.'
}
try {
    $inventoryText = [Text.UTF8Encoding]::new($false, $true).GetString(
        $inventoryBytes
    )
    $inventory = $inventoryText | ConvertFrom-Json
}
catch { throw 'Bundle source inventory is not strict UTF-8 JSON.' }
$inventoryProperties = @($inventory.PSObject.Properties | ForEach-Object {
    [string]$_.Name
})
if (($inventoryProperties -join ',') -cne 'schema,kind,entryPoint,sources' -or
    [long]$inventory.schema -ne 1 -or
    [string]$inventory.kind -cne 'meandai.quick-adoption.bundle-sources') {
    throw 'Bundle source inventory has an unsupported identity or shape.'
}
$entryPoint = [string]$inventory.entryPoint
$sourcePaths = @($inventory.sources | ForEach-Object { [string]$_ })
if ($sourcePaths.Count -lt 1 -or $sourcePaths.Count -gt 64 -or
    $sourcePaths -cnotcontains $entryPoint) {
    throw 'Bundle source inventory has an invalid bounded entry-point set.'
}

$seenPaths = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)
$payload = [Collections.Generic.List[object]]::new()
$payloadBytes = [Collections.Generic.Dictionary[string, byte[]]]::new(
    [StringComparer]::Ordinal
)
$sha256 = [Security.Cryptography.SHA256]::Create()
[long]$totalSourceBytes = 0
try {
    foreach ($bundlePath in $sourcePaths) {
        if ($bundlePath -cnotmatch '^MeAndAI\.QuickAdoption/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+$' -or
            $bundlePath.Contains('\') -or -not $seenPaths.Add($bundlePath)) {
            throw "Bundle source path '$bundlePath' is unsafe or duplicated."
        }
        $sourceRelativePath = 'scripts/quick-adoption/' +
            $bundlePath.Substring('MeAndAI.QuickAdoption/'.Length)
        $sourcePath = Join-Path $resolvedSourceRoot `
            ($sourceRelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
        $item = Get-Item -LiteralPath $sourcePath -Force -ErrorAction Stop
        if ($item.PSIsContainer -or
            (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
            throw "Bundle source '$sourceRelativePath' is not one regular file."
        }
        $stage = @(Invoke-BundleGitText -WorkingDirectory $resolvedSourceRoot `
            -Arguments @('ls-files', '--stage', '--error-unmatch', '--', $sourceRelativePath))
        if ($stage.Count -ne 1 -or
            [string]$stage[0] -cnotmatch '^100(?:644|755) [0-9a-f]{40} 0\t') {
            throw "Bundle source '$sourceRelativePath' is not one exact tracked regular Git blob."
        }
        $bytes = Read-BundleGitBlob -WorkingDirectory $resolvedSourceRoot `
            -Commit $SourceCommit -RelativePath $sourceRelativePath `
            -MaximumBytes ($maximumBundleSourceBytes - $totalSourceBytes)
        $totalSourceBytes += [long]$bytes.LongLength
        $digest = ([BitConverter]::ToString(
            $sha256.ComputeHash($bytes)
        ) -replace '-', '').ToLowerInvariant()
        $payload.Add([ordered]@{
            path = $bundlePath
            length = [long]$bytes.LongLength
            sha256 = $digest
        })
        $payloadBytes.Add($bundlePath, $bytes)
    }
}
finally {
    $sha256.Dispose()
}

$manifest = [ordered]@{
    schema = 1
    kind = 'meandai.quick-adoption.module-bundle'
    runtimeRepository = $RuntimeRepository
    runtimeReleaseTag = $RuntimeReleaseTag
    sourceCommit = $SourceCommit
    entryPoint = $entryPoint
    minimumPowerShellVersion = '5.1'
    payload = @($payload)
}
$manifestBytes = [Text.UTF8Encoding]::new($false).GetBytes(
    ($manifest | ConvertTo-Json -Depth 8 -Compress)
)

$fullOutputPath = [IO.Path]::GetFullPath($OutputPath)
$outputParent = Split-Path -Parent $fullOutputPath
if (-not (Test-Path -LiteralPath $outputParent -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $outputParent -Force)
}

Add-Type -AssemblyName System.IO.Compression
if (Test-Path -LiteralPath $fullOutputPath) {
    throw "Bundle output already exists: $fullOutputPath"
}
$fixedTimestamp = [DateTimeOffset]::new(
    1980, 1, 1, 0, 0, 0, [TimeSpan]::Zero
)
$buildSucceeded = $false
try {
    $fileStream = [IO.File]::Open(
        $fullOutputPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write,
        [IO.FileShare]::None
    )
    $archive = $null
    try {
        $archive = [IO.Compression.ZipArchive]::new(
            $fileStream, [IO.Compression.ZipArchiveMode]::Create, $false,
            [Text.Encoding]::UTF8
        )
        foreach ($entrySource in @(
            [pscustomobject]@{ Path = 'manifest.json'; Bytes = $manifestBytes }
        ) + @($sourcePaths | ForEach-Object {
            [pscustomobject]@{ Path = $_; Bytes = $payloadBytes[$_] }
        })) {
            $entry = $archive.CreateEntry(
                [string]$entrySource.Path,
                [IO.Compression.CompressionLevel]::NoCompression
            )
            $entry.LastWriteTime = $fixedTimestamp
            $stream = $entry.Open()
            try {
                $bytes = [byte[]]$entrySource.Bytes
                $stream.Write($bytes, 0, $bytes.Length)
            }
            finally { $stream.Dispose() }
        }
    }
    finally {
        if ($null -ne $archive) { $archive.Dispose() }
        $fileStream.Dispose()
    }
    $resultHash = (Get-FileHash -LiteralPath $fullOutputPath `
        -Algorithm SHA256).Hash.ToLowerInvariant()
    $buildSucceeded = $true
}
finally {
    if (-not $buildSucceeded -and (Test-Path -LiteralPath $fullOutputPath)) {
        Remove-Item -LiteralPath $fullOutputPath -Force
    }
}

[pscustomobject]@{
    Path = $fullOutputPath
    Sha256 = $resultHash
    Length = [long](Get-Item -LiteralPath $fullOutputPath).Length
    SourceCommit = $SourceCommit
    RuntimeReleaseTag = $RuntimeReleaseTag
}
