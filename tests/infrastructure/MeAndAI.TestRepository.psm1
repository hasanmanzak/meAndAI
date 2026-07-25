Set-StrictMode -Version Latest

function Invoke-MeAndAITestRepositoryGit {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Arguments,
        [string[]]$Configuration = @(),
        [switch]$BareRepository
    )

    $isBareRepository = $BareRepository -or (
        (Test-Path -LiteralPath (Join-Path $Repository 'HEAD') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Repository 'config') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Repository 'objects') -PathType Container) -and
        -not (Test-Path -LiteralPath (Join-Path $Repository '.git'))
    )
    $repositoryArguments = @(
        if ($isBareRepository) {
            "--git-dir=$Repository"
        }
        else {
            '-C'
            $Repository
        }
    )
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& git @Configuration @repositoryArguments @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -ne 0) {
        $repositoryMode = if ($isBareRepository) { '--git-dir' } else { '-C' }
        throw "git $repositoryMode $Repository $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    return @($output | ForEach-Object { [string]$_ })
}

function New-MeAndAITestCommit {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][scriptblock]$Change
    )

    & $Change
    Invoke-MeAndAITestRepositoryGit -Repository $Repository `
        -Arguments @('add', '--all') | Out-Null
    Invoke-MeAndAITestRepositoryGit -Repository $Repository `
        -Arguments @('commit', '-m', $Message) | Out-Null
    return (@(Invoke-MeAndAITestRepositoryGit -Repository $Repository `
        -Arguments @('rev-parse', 'HEAD'))[0]).Trim()
}

Export-ModuleMember -Function @(
    'Invoke-MeAndAITestRepositoryGit'
    'New-MeAndAITestCommit'
)
