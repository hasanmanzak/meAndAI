$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$sourceFiles = @(
    'Private/Configuration.ps1',
    'Private/OutputAndNativeProcess.ps1',
    'Private/RepositoryAssessment.ps1',
    'Private/ProtocolReleaseAndAssets.ps1',
    'Private/ProposalOwnership.ps1',
    'Private/CodexRuntime.ps1',
    'Private/CompletionAndPublication.ps1',
    'Public/Invoke-MeAndAIQuickAdoption.ps1'
)

foreach ($relativePath in $sourceFiles) {
    $sourcePath = Join-Path $PSScriptRoot `
        ($relativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    $item = Get-Item -LiteralPath $sourcePath -Force -ErrorAction Stop
    if ($item.PSIsContainer -or
        (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
        throw "Quick-adoption module source '$relativePath' is not one regular file."
    }
    . $sourcePath
}

Export-ModuleMember -Function 'Invoke-MeAndAIQuickAdoption'
