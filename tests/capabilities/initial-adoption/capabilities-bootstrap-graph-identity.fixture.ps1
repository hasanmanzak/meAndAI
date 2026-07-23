[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Repository,
    [Parameter(Mandatory)][string]$Commit,
    [Parameter(Mandatory)][string]$ModulePath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$testGitBatchPath = Join-Path $PSScriptRoot `
    '../../infrastructure/MeAndAI.TestGitBatch.psm1'
Import-Module $testGitBatchPath -Force

function Invoke-GitBinary {
    param(
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$Arguments
    )

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.Arguments = $Arguments
    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $output = [IO.MemoryStream]::new()
    try {
        if (-not $process.Start()) {
            throw "git $Arguments did not start."
        }
        $process.StandardOutput.BaseStream.CopyTo($output)
        $errorText = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            throw "git $Arguments failed: $errorText"
        }
        return ,([byte[]]$output.ToArray())
    }
    finally {
        $output.Dispose()
        $process.Dispose()
    }
}


if ($Commit -cnotmatch '^[0-9a-f]{40}$') {
    throw 'The TEST-0153 graph fixture requires one exact commit.'
}
if (-not (Test-Path -LiteralPath $Repository -PathType Container) -or
    -not (Test-Path -LiteralPath $ModulePath -PathType Leaf)) {
    throw 'The TEST-0153 graph fixture inputs are unavailable.'
}

$treeBytes = Invoke-GitBinary -WorkingDirectory $Repository `
    -Arguments "ls-tree -r -t -z --full-tree $Commit --"
$treeText = [Text.UTF8Encoding]::new($false, $true).GetString($treeBytes)
$entries = [System.Collections.Generic.List[object]]::new()
foreach ($record in @($treeText.Split([char]0))) {
    if ([string]::IsNullOrEmpty($record)) { continue }
    $match = [regex]::Match(
        $record,
        '^(?<mode>[0-9]{6}) (?<type>blob|tree|commit) (?<sha>[0-9a-f]{40})\t(?<path>.+)$'
    )
    if (-not $match.Success) {
        throw "The TEST-0153 tree contains malformed record '$record'."
    }
    $entries.Add([pscustomobject]@{
        Path = [string]$match.Groups['path'].Value
        Mode = [string]$match.Groups['mode'].Value
        Type = [string]$match.Groups['type'].Value
        Sha = [string]$match.Groups['sha'].Value
    })
}
$loaded = @(Import-Module $ModulePath -Force -PassThru)
if ($loaded.Count -ne 1) {
    throw 'The TEST-0153 capabilities contract did not load exactly once.'
}
$module = $loaded[0]
$builder = $module.ExportedCommands['New-MeAndAIInstructionGraph']
$validator = $module.ExportedCommands['Test-MeAndAIExactInstructionGraph']
$identityGetter =
    $module.ExportedCommands['Get-MeAndAIInstructionGraphIdentity']
if ($null -eq $builder -or $null -eq $validator -or
    $null -eq $identityGetter) {
    throw 'The TEST-0153 capabilities contract lacks graph exports.'
}
$session = New-MeAndAITestGitBlobBatchSession `
    -Repository $Repository
$graph = $null
$primaryError = $null
$cleanupError = $null
try {
    $graph = & $builder -BaseHead $Commit -TreeEntries @($entries) `
        -ReadBlob $session.ReadBlob
    & $session.Complete $graph
    if (-not (& $validator -Graph $graph)) {
        throw 'The TEST-0153 fixture returned a non-exact graph.'
    }
}
catch {
    $primaryError = $_.Exception
}
finally {
    try { & $session.Abort }
    catch { $cleanupError = $_.Exception }
}
if ($null -ne $primaryError) {
    if ($null -ne $cleanupError) {
        throw [AggregateException]::new(
            ($primaryError.Message + ' Cleanup failed: ' +
                $cleanupError.Message),
            [Exception[]]@($primaryError, $cleanupError)
        )
    }
    throw $primaryError
}
if ($null -ne $cleanupError) { throw $cleanupError }
$identity = & $identityGetter -Graph $graph
Write-Output ('MEANDAI_TEST_GRAPH_IDENTITY=' +
    ($identity | ConvertTo-Json -Depth 30 -Compress))
