Set-StrictMode -Version Latest

$script:MaximumEvidenceBytes = 16 * 1024 * 1024

function Invoke-MeAndAIRepositoryGit {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string[]]$Arguments,
        [int[]]$AllowedExitCodes = @(0)
    )

    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& git -C $RepositoryRoot @Arguments 2>&1 |
            ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($AllowedExitCodes -cnotcontains $exitCode) {
        throw "Git repository evidence command failed with exit code $exitCode. $($output -join "`n")"
    }
    return [pscustomobject][ordered]@{
        ExitCode = $exitCode
        Output = $output
        Text = ($output -join "`n").Trim()
    }
}

function Assert-MeAndAIRepositoryRelativePath {
    param([Parameter(Mandatory)][string]$RelativePath)

    if ([string]::IsNullOrWhiteSpace($RelativePath) -or
        $RelativePath -cnotmatch '^[A-Za-z0-9._/-]+$' -or
        $RelativePath.StartsWith('/') -or
        $RelativePath.EndsWith('/') -or
        $RelativePath.Contains('//')) {
        throw 'Evidence path must be one canonical repository-relative path.'
    }
    foreach ($segment in @($RelativePath -split '/')) {
        if ($segment -ceq '.' -or $segment -ceq '..') {
            throw 'Evidence path must be one canonical repository-relative path.'
        }
    }
}

function Assert-MeAndAIContainedEvidencePath {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $path = [IO.Path]::GetFullPath(
        (Join-Path $root ($RelativePath.Replace(
            '/',
            [IO.Path]::DirectorySeparatorChar
        )))
    )
    $prefix = $root + [IO.Path]::DirectorySeparatorChar
    if (-not $path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Evidence path must be one canonical repository-relative path.'
    }
    return $path
}

function Assert-MeAndAIOrdinaryEvidenceFile {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$LiteralPath
    )

    $current = [IO.Path]::GetFullPath($RepositoryRoot)
    if (([IO.File]::GetAttributes($current) -band
            [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Repository evidence root must not be a link or reparse point.'
    }
    foreach ($segment in @($RelativePath -split '/')) {
        $current = Join-Path $current $segment
        if (Test-Path -LiteralPath $current) {
            $attributes = [IO.File]::GetAttributes($current)
            if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw 'Worktree evidence must be an ordinary contained file.'
            }
        }
    }
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) {
        throw 'Worktree evidence deletion is not a supported byte source.'
    }
}

function Assert-MeAndAINoReparseEvidenceBoundary {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $current = [IO.Path]::GetFullPath($RepositoryRoot)
    foreach ($segment in @('') + @($RelativePath -split '/')) {
        if (-not [string]::IsNullOrEmpty($segment)) {
            $current = Join-Path $current $segment
        }
        if (Test-Path -LiteralPath $current) {
            $attributes = [IO.File]::GetAttributes($current)
            if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw 'Repository evidence crosses a link or reparse point.'
            }
        }
    }
}

function Read-MeAndAIWorktreeEvidenceBytes {
    param([Parameter(Mandatory)][string]$LiteralPath)

    $file = [IO.FileInfo]::new($LiteralPath)
    if ($file.Length -gt $script:MaximumEvidenceBytes) {
        throw 'Worktree evidence exceeds the bounded byte limit.'
    }
    $expectedLength = $file.Length
    $bytes = [IO.File]::ReadAllBytes($LiteralPath)
    $file.Refresh()
    if ($bytes.LongLength -ne $expectedLength -or
        $file.Length -ne $expectedLength) {
        throw 'Worktree evidence changed during bounded byte acquisition.'
    }
    return ,([byte[]]$bytes)
}

function Get-MeAndAIGitBlobBytes {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$ObjectId
    )

    if ($ObjectId -cnotmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$') {
        throw 'Repository evidence blob identity is not canonical.'
    }
    $type = Invoke-MeAndAIRepositoryGit -RepositoryRoot $RepositoryRoot `
        -Arguments @('cat-file', '-t', $ObjectId)
    if ($type.Text -cne 'blob') {
        throw 'Repository evidence object is not a regular blob.'
    }
    $sizeResult = Invoke-MeAndAIRepositoryGit -RepositoryRoot $RepositoryRoot `
        -Arguments @('cat-file', '-s', $ObjectId)
    [long]$expectedLength = 0
    if (-not [long]::TryParse(
            $sizeResult.Text,
            [Globalization.NumberStyles]::None,
            [Globalization.CultureInfo]::InvariantCulture,
            [ref]$expectedLength
        ) -or
        $expectedLength -lt 0 -or
        $expectedLength -gt $script:MaximumEvidenceBytes) {
        throw 'Repository evidence blob exceeds the bounded byte limit.'
    }

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.WorkingDirectory = $RepositoryRoot
    $startInfo.Arguments = "cat-file blob $ObjectId"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $stream = [IO.MemoryStream]::new()
    try {
        if (-not $process.Start()) {
            throw 'Git did not start for binary repository evidence acquisition.'
        }
        $errorTask = $process.StandardError.ReadToEndAsync()
        $process.StandardOutput.BaseStream.CopyTo($stream)
        $process.WaitForExit()
        $errorText = $errorTask.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) {
            throw "Repository evidence blob could not be read. $errorText"
        }
        if ($stream.Length -ne $expectedLength) {
            throw 'Repository evidence blob length changed during acquisition.'
        }
        return ,([byte[]]$stream.ToArray())
    }
    finally {
        $stream.Dispose()
        $process.Dispose()
    }
}

function Get-MeAndAIHeadEntry {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$Head,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $result = Invoke-MeAndAIRepositoryGit -RepositoryRoot $RepositoryRoot `
        -Arguments @('ls-tree', $Head, '--', $RelativePath)
    if ([string]::IsNullOrWhiteSpace($result.Text)) {
        return $null
    }
    if ($result.Output.Count -ne 1 -or
        $result.Output[0] -cnotmatch
            '^(?<mode>[0-9]{6}) (?<type>[a-z]+) (?<oid>[0-9a-f]{40}|[0-9a-f]{64})\t(?<path>.+)$' -or
        [string]$Matches['path'] -cne $RelativePath) {
        throw 'Requested HEAD evidence is not one exact repository entry.'
    }
    return [pscustomobject][ordered]@{
        Mode = [string]$Matches['mode']
        Type = [string]$Matches['type']
        ObjectId = [string]$Matches['oid']
    }
}

function Get-MeAndAIIndexEntries {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $result = Invoke-MeAndAIRepositoryGit -RepositoryRoot $RepositoryRoot `
        -Arguments @('ls-files', '--stage', '--', $RelativePath)
    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($line in @($result.Output)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -cnotmatch
            '^(?<mode>[0-9]{6}) (?<oid>[0-9a-f]{40}|[0-9a-f]{64}) (?<stage>[0-3])\t(?<path>.+)$' -or
            [string]$Matches['path'] -cne $RelativePath) {
            throw 'Index evidence is not one exact repository entry.'
        }
        $entries.Add([pscustomobject][ordered]@{
            Mode = [string]$Matches['mode']
            ObjectId = [string]$Matches['oid']
            Stage = [int]$Matches['stage']
        })
    }
    return @($entries)
}

function Test-MeAndAIRenameOrCopyState {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$Head,
        [Parameter(Mandatory)][string]$RelativePath,
        [AllowNull()][string]$IndexObjectId
    )

    $status = Invoke-MeAndAIRepositoryGit -RepositoryRoot $RepositoryRoot `
        -Arguments @(
            '-c', 'status.renames=copies',
            'status', '--porcelain=v1', '--untracked-files=all',
            '--', $RelativePath
        )
    if (@($status.Output | Where-Object {
        [string]$_ -cmatch '^[RC]'
    }).Count -gt 0) {
        return $true
    }
    $diff = Invoke-MeAndAIRepositoryGit -RepositoryRoot $RepositoryRoot `
        -Arguments @(
            'diff', '--cached', '--name-status',
            '--find-renames=50%', '--find-copies=100%',
            '--find-copies-harder', $Head, '--', $RelativePath
        )
    if (@($diff.Output | Where-Object {
        [string]$_ -cmatch '^[RC][0-9]{1,3}\s'
    }).Count -gt 0) {
        return $true
    }
    if ([string]::IsNullOrWhiteSpace($IndexObjectId)) {
        return $false
    }

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.WorkingDirectory = $RepositoryRoot
    $startInfo.Arguments = "ls-tree -r --full-tree $Head"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) {
            throw 'Git did not start for bounded rename/copy evidence.'
        }
        $errorTask = $process.StandardError.ReadToEndAsync()
        $count = 0
        $renameOrCopy = $false
        while (-not $process.StandardOutput.EndOfStream) {
            $line = $process.StandardOutput.ReadLine()
            $count++
            if ($count -gt 100000) {
                $process.Kill()
                $process.WaitForExit()
                throw 'Rename/copy candidate set exceeds the bounded entry limit.'
            }
            if ($line -cmatch
                    '^[0-9]{6} blob (?<oid>[0-9a-f]{40}|[0-9a-f]{64})\t(?<path>.+)$' -and
                [string]$Matches['oid'] -ceq $IndexObjectId -and
                [string]$Matches['path'] -cne $RelativePath) {
                $renameOrCopy = $true
            }
        }
        $process.WaitForExit()
        $errorText = $errorTask.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) {
            throw "Rename/copy evidence could not be read. $errorText"
        }
        return $renameOrCopy
    }
    finally {
        $process.Dispose()
    }
}

function Test-MeAndAIUntrackedPath {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $result = Invoke-MeAndAIRepositoryGit -RepositoryRoot $RepositoryRoot `
        -Arguments @('ls-files', '--others', '--exclude-standard', '--', $RelativePath)
    return @($result.Output | Where-Object {
        [string]$_ -ceq $RelativePath
    }).Count -eq 1
}

function New-MeAndAIRepositoryEvidenceResult {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Missing', 'Head', 'Index', 'Worktree')]
        [string]$Source,
        [AllowNull()][byte[]]$Bytes,
        [AllowNull()][string]$ObjectId
    )

    return [pscustomobject][ordered]@{
        Source = $Source
        Bytes = $Bytes
        ObjectId = $ObjectId
    }
}

function Get-MeAndAIRepositoryEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Head
    )

    Assert-MeAndAIRepositoryRelativePath -RelativePath $RelativePath
    if ($Head -cnotmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$') {
        throw 'Requested repository-evidence HEAD is not canonical.'
    }
    if (-not (Test-Path -LiteralPath $RepositoryRoot -PathType Container)) {
        throw 'Repository evidence root does not exist.'
    }
    $root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $top = (Invoke-MeAndAIRepositoryGit -RepositoryRoot $root `
        -Arguments @('rev-parse', '--show-toplevel')).Text
    $topFull = [IO.Path]::GetFullPath($top).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    if (-not $topFull.Equals($root, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'RepositoryRoot is not the exact Git checkout root.'
    }
    Assert-MeAndAINoReparseEvidenceBoundary -RepositoryRoot $root `
        -RelativePath $RelativePath
    $headType = Invoke-MeAndAIRepositoryGit -RepositoryRoot $root `
        -Arguments @('cat-file', '-t', $Head)
    if ($headType.Text -cne 'commit') {
        throw 'Requested repository-evidence HEAD is not one commit.'
    }
    $checkoutHead = (Invoke-MeAndAIRepositoryGit -RepositoryRoot $root `
        -Arguments @('rev-parse', 'HEAD')).Text
    if ($checkoutHead -cne $Head) {
        throw 'Requested repository-evidence HEAD is not the checked-out HEAD.'
    }
    $literalPath = Assert-MeAndAIContainedEvidencePath `
        -RepositoryRoot $root -RelativePath $RelativePath
    $headEntry = Get-MeAndAIHeadEntry -RepositoryRoot $root `
        -Head $Head -RelativePath $RelativePath
    $indexEntries = @(Get-MeAndAIIndexEntries -RepositoryRoot $root `
        -RelativePath $RelativePath)
    if ($indexEntries.Count -gt 1 -or
        @($indexEntries | Where-Object { $_.Stage -ne 0 }).Count -gt 0) {
        throw 'Repository evidence index is conflicted or lacks one stage-zero authority.'
    }
    $indexEntry = if ($indexEntries.Count -eq 1) {
        $indexEntries[0]
    } else {
        $null
    }
    foreach ($entry in @($headEntry, $indexEntry)) {
        if ($null -eq $entry) { continue }
        if (@('100644', '100755') -cnotcontains [string]$entry.Mode -or
            ($entry.PSObject.Properties.Name -ccontains 'Type' -and
                [string]$entry.Type -cne 'blob')) {
            throw 'Repository evidence must resolve to one regular blob.'
        }
    }
    $candidateObjectId = if ($null -eq $headEntry -and
        $null -ne $indexEntry) {
        [string]$indexEntry.ObjectId
    } else {
        $null
    }
    if (Test-MeAndAIRenameOrCopyState -RepositoryRoot $root `
            -Head $Head -RelativePath $RelativePath `
            -IndexObjectId $candidateObjectId) {
        throw 'Repository evidence rename or copy state is ambiguous.'
    }

    $staged = if ($null -eq $headEntry -or $null -eq $indexEntry) {
        -not ($null -eq $headEntry -and $null -eq $indexEntry)
    } else {
        [string]$headEntry.Mode -cne [string]$indexEntry.Mode -or
        [string]$headEntry.ObjectId -cne [string]$indexEntry.ObjectId
    }
    $unstagedResult = Invoke-MeAndAIRepositoryGit -RepositoryRoot $root `
        -Arguments @('diff', '--quiet', '--no-ext-diff', '--', $RelativePath) `
        -AllowedExitCodes @(0, 1)
    $unstaged = $unstagedResult.ExitCode -eq 1
    $untracked = Test-MeAndAIUntrackedPath -RepositoryRoot $root `
        -RelativePath $RelativePath

    if ($staged) {
        if ($null -eq $indexEntry) {
            throw 'Repository evidence staged deletion is not supported.'
        }
        if ($unstaged -or $untracked) {
            throw 'Repository evidence has staged and unstaged state.'
        }
        $bytes = Get-MeAndAIGitBlobBytes -RepositoryRoot $root `
            -ObjectId ([string]$indexEntry.ObjectId)
        return New-MeAndAIRepositoryEvidenceResult -Source Index `
            -Bytes $bytes -ObjectId ([string]$indexEntry.ObjectId)
    }

    if ($null -ne $headEntry) {
        if ($unstaged) {
            Assert-MeAndAIOrdinaryEvidenceFile -RepositoryRoot $root `
                -RelativePath $RelativePath -LiteralPath $literalPath
            return New-MeAndAIRepositoryEvidenceResult -Source Worktree `
                -Bytes (Read-MeAndAIWorktreeEvidenceBytes `
                    -LiteralPath $literalPath) -ObjectId $null
        }
        $bytes = Get-MeAndAIGitBlobBytes -RepositoryRoot $root `
            -ObjectId ([string]$headEntry.ObjectId)
        return New-MeAndAIRepositoryEvidenceResult -Source Head `
            -Bytes $bytes -ObjectId ([string]$headEntry.ObjectId)
    }

    if ($untracked) {
        Assert-MeAndAIOrdinaryEvidenceFile -RepositoryRoot $root `
            -RelativePath $RelativePath -LiteralPath $literalPath
        return New-MeAndAIRepositoryEvidenceResult -Source Worktree `
            -Bytes (Read-MeAndAIWorktreeEvidenceBytes `
                -LiteralPath $literalPath) -ObjectId $null
    }
    if (Test-Path -LiteralPath $literalPath) {
        $ignored = Invoke-MeAndAIRepositoryGit -RepositoryRoot $root `
            -Arguments @('check-ignore', '--quiet', '--', $RelativePath) `
            -AllowedExitCodes @(0, 1)
        if ($ignored.ExitCode -eq 0) {
            throw 'Ignored worktree evidence has no supported byte authority.'
        }
        throw 'Worktree evidence state is ambiguous.'
    }
    return New-MeAndAIRepositoryEvidenceResult -Source Missing `
        -Bytes $null -ObjectId $null
}

Export-ModuleMember -Function Get-MeAndAIRepositoryEvidence
