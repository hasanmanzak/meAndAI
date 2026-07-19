[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('pull_request', 'push', 'workflow_dispatch', 'merge_group')]
    [string]$EventName,
    [string]$BaseCommit = '',
    [string]$HeadCommit = '',
    [string]$RepositoryRoot = (Join-Path $PSScriptRoot '../../..')
)

$ErrorActionPreference = 'Stop'
$fullProfile = 'Full'
$nativeProfile = 'WindowsNative'
$maximumChangedPaths = 300

function Invoke-ReadOnlyGit {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& git -C $RepositoryRoot @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($output | ForEach-Object { [string]$_ })
    }
}

function Test-SensitivePath {
    param([Parameter(Mandatory)][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or
        $Path.StartsWith('/', [StringComparison]::Ordinal) -or
        $Path.Contains("`t") -or $Path.Contains('\') -or
        $Path.Contains('"') -or
        @($Path.Split('/') | Where-Object {
            $_ -ceq '' -or $_ -ceq '.' -or $_ -ceq '..'
        }).Count -gt 0) {
        return $true
    }
    if ($Path -match '\.(?:ps1|psm1|psd1|ps1xml|cmd|bat)$') {
        return $true
    }
    if ($Path -match '(?:^|/)\.github/(?:workflows|actions)/.*\.(?:yml|yaml)$') {
        return $true
    }
    if ($Path -match '(?:^|/)migrations/.*\.json$') {
        return $true
    }
    return $Path -in @('.gitattributes', '.gitmodules')
}

try {
    if ($EventName -cin @('workflow_dispatch', 'merge_group')) {
        Write-Output $fullProfile
        return
    }
    if ($BaseCommit -cnotmatch '^[0-9a-f]{40}$' -or
        $HeadCommit -cnotmatch '^[0-9a-f]{40}$') {
        Write-Output $fullProfile
        return
    }
    $repositoryPath = [IO.Path]::GetFullPath($RepositoryRoot)
    if (-not (Test-Path -LiteralPath $repositoryPath -PathType Container)) {
        Write-Output $fullProfile
        return
    }
    $RepositoryRoot = $repositoryPath

    foreach ($commit in @($BaseCommit, $HeadCommit)) {
        $commitResult = Invoke-ReadOnlyGit -Arguments @(
            'cat-file', '-e', "$commit`^{commit}"
        )
        if ($commitResult.ExitCode -ne 0) {
            Write-Output $fullProfile
            return
        }
    }

    $diff = Invoke-ReadOnlyGit -Arguments @(
        '-c', 'core.quotePath=false',
        'diff', '--no-renames', '--name-only',
        '--diff-filter=ACDMRTUXB', $BaseCommit, $HeadCommit, '--'
    )
    if ($diff.ExitCode -ne 0) {
        Write-Output $fullProfile
        return
    }
    $paths = @($diff.Output | Where-Object {
        -not [string]::IsNullOrWhiteSpace([string]$_)
    } | ForEach-Object { [string]$_ })
    if ($paths.Count -eq 0 -or $paths.Count -gt $maximumChangedPaths) {
        Write-Output $fullProfile
        return
    }
    foreach ($path in $paths) {
        if (Test-SensitivePath -Path $path) {
            Write-Output $fullProfile
            return
        }
    }

    Write-Output $nativeProfile
}
catch {
    Write-Output $fullProfile
}
