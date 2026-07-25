$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$contentIdentityCandidates = @(@(
    (Join-Path $PSScriptRoot 'MeAndAI.ContentIdentity.psm1'),
    (Join-Path (Split-Path -Parent $PSScriptRoot) 'MeAndAI.ContentIdentity.psm1')
) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
if ($contentIdentityCandidates.Count -ne 1) {
    throw 'Quick-adoption requires one unambiguous canonical content-identity module.'
}
$contentIdentityModule = @(Import-Module `
    $contentIdentityCandidates[0] -Force -PassThru)
if ($contentIdentityModule.Count -ne 1 -or
    $null -eq $contentIdentityModule[0].ExportedCommands['Get-MeAndAIGitBlobSha1'] -or
    $null -eq $contentIdentityModule[0].ExportedCommands['Test-MeAndAIByteArrayEqual']) {
    throw 'Quick-adoption could not load the canonical Git blob identity contract.'
}
$script:GetQuickAdoptionGitBlobSha1 = $contentIdentityModule[0].ExportedCommands[
    'Get-MeAndAIGitBlobSha1'
].ScriptBlock
$script:TestQuickAdoptionByteArrayEqual = $contentIdentityModule[0].ExportedCommands[
    'Test-MeAndAIByteArrayEqual'
].ScriptBlock

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
