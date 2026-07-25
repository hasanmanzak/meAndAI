Set-StrictMode -Version Latest

function New-MeAndAITestDirectoryLink {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Target
    )

    if ($env:OS -eq 'Windows_NT') {
        New-Item -ItemType Junction -Path $Path -Target $Target |
            Out-Null
    }
    else {
        New-Item -ItemType SymbolicLink -Path $Path -Target $Target |
            Out-Null
    }
}

Export-ModuleMember -Function 'New-MeAndAITestDirectoryLink'
