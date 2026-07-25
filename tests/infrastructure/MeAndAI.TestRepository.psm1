Set-StrictMode -Version Latest

function Invoke-MeAndAITestRepositoryGit {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& git -C $Repository @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -ne 0) {
        throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
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

Export-ModuleMember -Function 'New-MeAndAITestCommit'
