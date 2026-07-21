$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$owner = 'tests/capabilities/instruction-graph-discovery/instruction-graph-discovery.tests.ps1'
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
$modulePath = Join-Path $root `
    'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
$quickAssessmentPath = Join-Path $root `
    'scripts/quick-adoption/Private/RepositoryAssessment.ps1'
$hostedAdapterPath = Join-Path $root `
    'templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1'
Import-Module (Join-Path $root `
    'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { Add-Failure $Message }
}

function Assert-SequenceEqual {
    param([object[]]$Actual, [object[]]$Expected, [string]$Message)

    if ($Actual.Count -ne $Expected.Count) {
        Add-Failure "$Message Count differs: $($Actual.Count) != $($Expected.Count)."
        return
    }
    for ($index = 0; $index -lt $Actual.Count; $index++) {
        if ([string]$Actual[$index] -cne [string]$Expected[$index]) {
            Add-Failure "$Message Element $index differs: '$($Actual[$index])' != '$($Expected[$index])'."
            return
        }
    }
}

function Assert-ThrowsLike {
    param([scriptblock]$Action, [string]$Pattern, [string]$Message)

    try { & $Action }
    catch {
        if ($_.Exception.Message -like $Pattern) { return }
        Add-Failure "$Message Unexpected error: $($_.Exception.Message)"
        return
    }
    Add-Failure "$Message No error was thrown."
}

function Copy-TestInstructionGraph {
    param([Parameter(Mandatory)]$Graph)

    return $Graph | ConvertTo-Json -Depth 30 | ConvertFrom-Json
}

function Set-TestInstructionGraphDigest {
    param(
        [Parameter(Mandatory)]$Graph,
        [Parameter(Mandatory)]
        [Management.Automation.PSModuleInfo]$PolicyModule
    )

    $Graph.digest = & $PolicyModule {
        param($record)
        Get-MeAndAIInstructionGraphDigest -Graph $record
    } $Graph
}

function Sort-TestInstructionGraphRoots {
    param([Parameter(Mandatory)][object[]]$Roots)

    $ordered = [Collections.Generic.SortedDictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($root in $Roots) {
        $ordered.Add([string]$root.path, $root)
    }
    return @($ordered.Values)
}

function Sort-TestInstructionGraphPathRecords {
    param([Parameter(Mandatory)][object[]]$Records)

    $ordered = [Collections.Generic.SortedDictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($record in $Records) {
        $ordered.Add([string]$record.path, $record)
    }
    return @($ordered.Values)
}

function Sort-TestInstructionGraphEdges {
    param([Parameter(Mandatory)][object[]]$Edges)

    $ordered = [Collections.Generic.SortedDictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($edge in $Edges) {
        $key = "$([string]$edge.source)`0$([string]$edge.target)`0" +
            "$([string]$edge.kind)`0$([string]$edge.anchor)`0" +
            "$([string]$edge.reason)`0$([bool]$edge.external)"
        $ordered.Add($key, $edge)
    }
    return @($ordered.Values)
}

function Get-TestGitBlobSha {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $header = [Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
    $payload = [byte[]]::new($header.Length + $Bytes.Length)
    [Array]::Copy($header, 0, $payload, 0, $header.Length)
    [Array]::Copy($Bytes, 0, $payload, $header.Length, $Bytes.Length)
    $sha = [Security.Cryptography.SHA1]::Create()
    try {
        return ([BitConverter]::ToString(
            $sha.ComputeHash($payload)
        )).Replace('-', '').ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

function Get-TestSha256Hex {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString(
            $sha.ComputeHash($Bytes)
        )).Replace('-', '').ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

function New-TestTreeEntry {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Mode = '100644',
        [string]$Type = 'blob',
        [string]$Sha = ('f' * 40)
    )

    return [pscustomobject]@{
        Path = $Path
        Mode = $Mode
        Type = $Type
        Sha = $Sha
    }
}

function New-TestByteGraphFixture {
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Files,
        [System.Collections.IDictionary]$SpecialEntries = @{}
    )

    $blobs = @{}
    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($path in @($Files.Keys | Sort-Object)) {
        [byte[]]$bytes = [byte[]]$Files[$path]
        $blobs[[string]$path] = $bytes
        $entries.Add((New-TestTreeEntry -Path ([string]$path) `
            -Sha (Get-TestGitBlobSha -Bytes $bytes)))
    }
    foreach ($path in @($SpecialEntries.Keys | Sort-Object)) {
        $entry = $SpecialEntries[$path]
        $entries.Add((New-TestTreeEntry -Path ([string]$path) `
            -Mode ([string]$entry.Mode) -Type ([string]$entry.Type) `
            -Sha ([string]$entry.Sha)))
    }
    return [pscustomobject]@{
        Entries = @($entries)
        Blobs = $blobs
        Reader = {
            param($entry)
            if (-not $blobs.ContainsKey([string]$entry.Path)) {
                throw "No exact blob evidence exists for '$([string]$entry.Path)'."
            }
            return ,([byte[]]$blobs[[string]$entry.Path])
        }.GetNewClosure()
    }
}

function New-TestGraphFixture {
    param([hashtable]$Files, [hashtable]$SpecialEntries = @{})

    $blobs = @{}
    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($path in @($Files.Keys | Sort-Object)) {
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes([string]$Files[$path])
        $blobs[$path] = $bytes
        $entries.Add([pscustomobject]@{
            Path = [string]$path
            Mode = '100644'
            Type = 'blob'
            Sha = Get-TestGitBlobSha -Bytes $bytes
        })
    }
    foreach ($path in @($SpecialEntries.Keys | Sort-Object)) {
        $entry = $SpecialEntries[$path]
        $entries.Add([pscustomobject]@{
            Path = [string]$path
            Mode = [string]$entry.Mode
            Type = [string]$entry.Type
            Sha = [string]$entry.Sha
        })
    }
    return [pscustomobject]@{
        Entries = @($entries)
        Blobs = $blobs
        Reader = {
            param($entry)
            if (-not $blobs.ContainsKey([string]$entry.Path)) {
                throw "No exact blob evidence exists for '$([string]$entry.Path)'."
            }
            return ,([byte[]]$blobs[[string]$entry.Path])
        }.GetNewClosure()
    }
}

function Invoke-TestGitBytes {
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

function Get-TestCommittedGraphFixture {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$BaseHead
    )

    $treeBytes = Invoke-TestGitBytes -WorkingDirectory $RepositoryRoot `
        -Arguments "ls-tree -r -t -z --full-tree $BaseHead"
    $treeText = [Text.UTF8Encoding]::new($false, $true).GetString($treeBytes)
    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($record in @($treeText.Split([char]0))) {
        if ([string]::IsNullOrEmpty($record)) { continue }
        $match = [regex]::Match(
            $record,
            '^(?<mode>[0-9]{6}) (?<type>blob|tree|commit) (?<sha>[0-9a-f]{40})\t(?<path>.+)$'
        )
        if (-not $match.Success) {
            throw "Unexpected exact Git tree record '$record'."
        }
        $entries.Add((New-TestTreeEntry `
            -Path ([string]$match.Groups['path'].Value) `
            -Mode ([string]$match.Groups['mode'].Value) `
            -Type ([string]$match.Groups['type'].Value) `
            -Sha ([string]$match.Groups['sha'].Value)))
    }
    $gitBytes = ${function:Invoke-TestGitBytes}
    return [pscustomobject]@{
        Entries = @($entries)
        Reader = {
            param($entry)
            return ,(& $gitBytes -WorkingDirectory $RepositoryRoot `
                -Arguments "cat-file blob $([string]$entry.Sha)")
        }.GetNewClosure()
    }
}

function Invoke-TestGitCommand {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $global:LASTEXITCODE = 0
        $output = @(& git -C $RepositoryRoot @Arguments 2>&1)
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

function Set-TestFixtureBytes {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][byte[]]$Bytes
    )

    $parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrEmpty($parent)) {
        [void][IO.Directory]::CreateDirectory($parent)
    }
    [IO.File]::WriteAllBytes($Path, $Bytes)
}

function New-TestHostedGraphAcquisitionModule {
    param(
        [Parameter(Mandatory)][string]$AdapterPath,
        [Parameter(Mandatory)][string]$PolicyModulePath
    )

    $tokens = $null
    $parseErrors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile(
        $AdapterPath, [ref]$tokens, [ref]$parseErrors
    )
    if (@($parseErrors).Count -ne 0) {
        throw "Hosted adapter could not be parsed: $($parseErrors[0].Message)"
    }
    $requiredNames = @(
        'Get-InstructionGraphTreeEntries',
        'Get-InstructionGraphBlobBytes',
        'Get-InstructionGraphForCommit'
    )
    $definitions = @($ast.FindAll({
        param($node)
        return $node -is [Management.Automation.Language.FunctionDefinitionAst]
    }, $true))
    $source = [System.Collections.Generic.List[string]]::new()
    foreach ($name in $requiredNames) {
        $matches = @($definitions | Where-Object { $_.Name -ceq $name })
        if ($matches.Count -ne 1) {
            throw "Hosted adapter must define '$name' exactly once."
        }
        $source.Add([string]$matches[0].Extent.Text)
    }

    $factory = {
        param($ModulePath, $FunctionSource)
        Import-Module $ModulePath -Force
        . ([scriptblock]::Create($FunctionSource))
    }
    $module = New-Module -Name (
        'MeAndAI.TestHostedGraphAcquisition.' + [Guid]::NewGuid().ToString('N')
    ) -ScriptBlock $factory -ArgumentList @(
        $PolicyModulePath,
        [string]::Join([Environment]::NewLine, @($source))
    )
    return $module
}

function New-TestDepthFixture {
    param([Parameter(Mandatory)][int]$Depth)

    $files = [ordered]@{}
    if ($Depth -eq 0) {
        $files['AGENTS.md'] = 'No further reading.'
        return New-TestGraphFixture -Files $files
    }
    $files['AGENTS.md'] = 'Required reading: [next](docs/depth/01.md).'
    for ($level = 1; $level -le $Depth; $level++) {
        $path = 'docs/depth/{0:D2}.md' -f $level
        $files[$path] = if ($level -lt $Depth) {
            'Required reading: [next]({0:D2}.md).' -f ($level + 1)
        }
        else { 'No further reading.' }
    }
    return New-TestGraphFixture -Files $files
}

function New-TestProtectedTerminalDepthFixture {
    param([Parameter(Mandatory)][int]$TextDepth)

    $files = [ordered]@{}
    if ($TextDepth -eq 0) {
        $files['AGENTS.md'] =
            'Reference [evidence](docs/depth/evidence.pdf).'
    }
    else {
        $files['AGENTS.md'] = 'Required reading: [next](docs/depth/01.md).'
        for ($level = 1; $level -le $TextDepth; $level++) {
            $path = 'docs/depth/{0:D2}.md' -f $level
            $files[$path] = if ($level -lt $TextDepth) {
                'Required reading: [next]({0:D2}.md).' -f ($level + 1)
            }
            else { 'Reference [evidence](evidence.pdf).' }
        }
    }
    $files['docs/depth/evidence.pdf'] = 'protected evidence'
    return New-TestGraphFixture -Files $files
}

function New-TestDepthBackEdgeFixture {
    param([Parameter(Mandatory)][int]$Depth)

    if ($Depth -lt 1) { throw 'Back-edge depth must be positive.' }
    $files = [ordered]@{
        'AGENTS.md' = 'Required reading: [next](docs/depth/01.md).'
    }
    for ($level = 1; $level -le $Depth; $level++) {
        $path = 'docs/depth/{0:D2}.md' -f $level
        $files[$path] = if ($level -lt $Depth) {
            'Required reading: [next]({0:D2}.md).' -f ($level + 1)
        }
        else { 'Reference [root](../../AGENTS.md).' }
    }
    return New-TestGraphFixture -Files $files
}

if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $quickAssessmentPath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $hostedAdapterPath -PathType Leaf)) {
    Add-Failure 'TEST-0151/TEST-0152 graph policy or acquisition adapter is missing.'
}
else {
    Import-Module $modulePath -Force
    . $quickAssessmentPath
    $policyModule = Get-Module MeAndAI.CapabilitiesBootstrap |
        Where-Object { $_.Path -ceq (Resolve-Path $modulePath).Path } |
        Select-Object -First 1
    $graphBuilder = Get-Command -Name 'New-MeAndAIInstructionGraph' `
        -CommandType Function -ErrorAction SilentlyContinue
    $limitGetter = Get-Command -Name 'Get-MeAndAIInstructionGraphLimits' `
        -CommandType Function -ErrorAction SilentlyContinue
    $graphValidator = Get-Command -Name 'Test-MeAndAIExactInstructionGraph' `
        -CommandType Function -ErrorAction SilentlyContinue
    $graphIdentityGetter = Get-Command `
        -Name 'Get-MeAndAIInstructionGraphIdentity' `
        -CommandType Function -ErrorAction SilentlyContinue
    $graphIdentityRecordValidator = Get-Command `
        -Name 'Test-MeAndAIExactInstructionGraphIdentityRecord' `
        -CommandType Function -ErrorAction SilentlyContinue
    $canonicalPathValidator = Get-Command `
        -Name 'Test-MeAndAICanonicalRepositoryPath' `
        -CommandType Function -ErrorAction SilentlyContinue
    $surfaceClassifier = Get-Command `
        -Name 'Get-MeAndAIProtocolSurfaceInventory' `
        -CommandType Function -ErrorAction SilentlyContinue

    if ($null -eq $policyModule -or $null -eq $graphBuilder -or
        $null -eq $limitGetter -or $null -eq $graphValidator -or
        $null -eq $graphIdentityGetter -or
        $null -eq $graphIdentityRecordValidator -or
        $null -eq $canonicalPathValidator -or
        $null -eq $surfaceClassifier) {
        Add-Failure 'TEST-0151/TEST-0152 canonical instruction-graph contract is not exported.'
    }
    else {
        $script:InitialAdoptionPolicy = [pscustomobject]@{
            Commands = @{}
        }
        foreach ($name in @(
            'Get-MeAndAIInstructionGraphLimits',
            'New-MeAndAIInstructionGraph',
            'Test-MeAndAIExactInstructionGraph'
        )) {
            $script:InitialAdoptionPolicy.Commands[$name] = Get-Command `
                -Name $name -CommandType Function
        }

        $files = [ordered]@{
            'AGENTS.md' = @'
# Instructions

Required reading: [AI memory](docs/AI_MEMORY.md).
External evidence: [example](https://example.com/evidence).

```text
docs/SHOULD_NOT_BE_DISCOVERED.md
```
'@
            'docs/AI_MEMORY.md' = 'Required reading: [development protocol](DEVELOPMENT_PROTOCOL.md).'
            'docs/DEVELOPMENT_PROTOCOL.md' = 'Canonical authority: [tracker](PROJECT_TRACKER.md).'
            'docs/PROJECT_TRACKER.md' = 'Index: [test catalog](TEST_CATALOG.md).'
            'docs/TEST_CATALOG.md' = 'Reference: [memory](AI_MEMORY.md).'
            'services/api/AGENTS.md' = 'Required reading: [memory](../../docs/AI_MEMORY.md).'
            'docs/governance/UNLINKED.md' = 'Legacy governance evidence.'
            'docs/UNSEEDED_AUTHORITY.md' = 'Canonical source of truth but intentionally unreachable.'
            'docs/architecture.md' = 'A benign architecture note.'
            'docs/SHOULD_NOT_BE_DISCOVERED.md' = 'Example-only path.'
        }
        $fixture = New-TestGraphFixture -Files $files
        $graph = & $graphBuilder -BaseHead ('a' * 40) `
            -TreeEntries $fixture.Entries -ReadBlob $fixture.Reader
        $repeat = & $graphBuilder -BaseHead ('a' * 40) `
            -TreeEntries $fixture.Entries -ReadBlob $fixture.Reader
        $shuffledEntries = @($fixture.Entries)
        [Array]::Reverse($shuffledEntries)
        $shuffled = & $graphBuilder -BaseHead ('a' * 40) `
            -TreeEntries $shuffledEntries -ReadBlob $fixture.Reader

        $graphIsExact = [bool](& $graphValidator -Graph $graph)
        Assert-True -Condition $graphIsExact `
            -Message 'TEST-0151 the generated graph failed its exact validator.'
        Assert-True -Condition ([string]$graph.digest -cmatch '^[0-9a-f]{64}$') `
            -Message 'TEST-0151 graph digest is not canonical lowercase SHA-256.'
        Assert-True -Condition ([string]$graph.digest -ceq [string]$repeat.digest) `
            -Message 'TEST-0151 repeated discovery changed the graph digest.'
        Assert-True -Condition ([string]$graph.digest -ceq [string]$shuffled.digest) `
            -Message 'TEST-0151 shuffled exact-tree input changed the graph digest.'
        Assert-True -Condition ([string]$graph.digest -ceq `
            '906f94ff5dcfbd41a39edbbb4f75f86798eacd96b895de27019018a333c6f6bd') `
            -Message "TEST-0151 fixed graph digest differs across supported hosts: $([string]$graph.digest)."
        $compactGraphJson = $graph | ConvertTo-Json -Depth 20 -Compress
        $compactGraphJsonSha = Get-TestSha256Hex -Bytes (
            [Text.UTF8Encoding]::new($false).GetBytes($compactGraphJson)
        )
        Assert-True -Condition ($compactGraphJsonSha -ceq `
            '7b535df7de8e398c80e652f84cfb5ee97bce1d8be30a10d6b4e33432e9503ad3') `
            -Message "TEST-0151 fixed compact graph serialization differs across supported hosts: $compactGraphJsonSha."
        Assert-True -Condition (
            ($graph | ConvertTo-Json -Depth 20 -Compress) -ceq
            ($repeat | ConvertTo-Json -Depth 20 -Compress) -and
            ($graph | ConvertTo-Json -Depth 20 -Compress) -ceq
            ($shuffled | ConvertTo-Json -Depth 20 -Compress)
        ) -Message 'TEST-0151 repeated or shuffled discovery was not byte-stable JSON.'
        Assert-SequenceEqual -Actual @($graph.protocolSurfaces) -Expected @(
            'AGENTS.md',
            'docs/AI_MEMORY.md',
            'docs/DEVELOPMENT_PROTOCOL.md',
            'docs/PROJECT_TRACKER.md',
            'docs/TEST_CATALOG.md',
            'docs/governance/UNLINKED.md',
            'services/api/AGENTS.md'
        ) -Message 'TEST-0151 reachable/custom and compatibility surfaces differ.'
        Assert-True -Condition (@($graph.nodes.path) -cnotcontains `
            'docs/UNSEEDED_AUTHORITY.md') `
            -Message 'TEST-0151 arbitrary unreachable authority wording was scanned.'
        Assert-True -Condition (@($graph.nodes.path) -cnotcontains `
            'docs/SHOULD_NOT_BE_DISCOVERED.md') `
            -Message 'TEST-0151 fenced example text created a graph node.'
        Assert-True -Condition (@($graph.nodes | Where-Object {
            $_.path -ceq 'docs/governance/UNLINKED.md' -and
            $_.role -ceq 'UnlinkedKnownSurfaceCandidate'
        }).Count -eq 1) `
            -Message 'TEST-0151 unlinked known-surface compatibility evidence was lost.'
        Assert-True -Condition (@($graph.edges | Where-Object {
            $_.kind -ceq 'Scopes' -and $_.source -ceq 'AGENTS.md' -and
            $_.target -ceq 'services/api/AGENTS.md'
        }).Count -eq 1) `
            -Message 'TEST-0151 nested AGENTS scope is not deterministic.'

        $currentSurfaceSeed = & $policyModule {
            [pscustomobject]@{
                Files = @($script:MeAndAIProtocolSurfaceFiles)
                Roots = @($script:MeAndAIProtocolSurfaceRoots)
            }
        }
        $surfaceVectorCases = [Collections.Generic.List[object]]::new()
        foreach ($surfaceFile in @($currentSurfaceSeed.Files)) {
            $surfaceVectorCases.Add([pscustomobject]@{
                Name = "file '$surfaceFile'"
                Path = [string]$surfaceFile
            })
        }
        foreach ($surfaceRoot in @($currentSurfaceSeed.Roots)) {
            $surfaceVectorCases.Add([pscustomobject]@{
                Name = "exact root '$surfaceRoot'"
                Path = ([string]$surfaceRoot).TrimEnd('/')
            })
            $surfaceVectorCases.Add([pscustomobject]@{
                Name = "root descendant '$surfaceRoot'"
                Path = ([string]$surfaceRoot) + 'compatibility-vector.bin'
            })
        }
        $surfaceVectorCases.Add([pscustomobject]@{
            Name = 'nested AGENTS convention'
            Path = 'nested/AGENTS.md'
        })
        foreach ($surfaceVectorCase in @($surfaceVectorCases)) {
            $surfaceVectorPath = [string]$surfaceVectorCase.Path
            $surfaceVectorFiles = [ordered]@{}
            $surfaceVectorFiles[$surfaceVectorPath] = 'No references.'
            $surfaceVectorFixture = New-TestGraphFixture `
                -Files $surfaceVectorFiles
            $surfaceVectorGraph = & $graphBuilder -BaseHead ('0' * 40) `
                -TreeEntries $surfaceVectorFixture.Entries `
                -ReadBlob $surfaceVectorFixture.Reader
            $classifiedSurface = @(& $surfaceClassifier `
                -Paths @($surfaceVectorPath))
            Assert-SequenceEqual -Actual $classifiedSurface `
                -Expected @($surfaceVectorPath) `
                -Message "TEST-0151 current $([string]$surfaceVectorCase.Name) is no longer classified."
            Assert-SequenceEqual -Actual @($surfaceVectorGraph.protocolSurfaces) `
                -Expected $classifiedSurface `
                -Message "TEST-0151 graph projection regressed from current $([string]$surfaceVectorCase.Name)."
        }

        $codeOnlyFixture = New-TestGraphFixture -Files ([ordered]@{
            'src/app.ps1' = 'Write-Output ''ordinary product code'''
        })
        $codeOnlyGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $codeOnlyFixture.Entries -ReadBlob {
                throw 'TEST-0151 ordinary code-only tree was dereferenced.'
            }
        Assert-True -Condition (
            [bool](& $graphValidator -Graph $codeOnlyGraph) -and
            @($codeOnlyGraph.roots).Count -eq 0 -and
            @($codeOnlyGraph.nodes).Count -eq 0 -and
            @($codeOnlyGraph.edges).Count -eq 0 -and
            @($codeOnlyGraph.candidates).Count -eq 0 -and
            @($codeOnlyGraph.protocolSurfaces).Count -eq 0 -and
            [long]$codeOnlyGraph.counts.treeEntries -eq 1 -and
            [long]$codeOnlyGraph.counts.treePathUtf8Bytes -eq
                [Text.Encoding]::UTF8.GetByteCount('src/app.ps1') -and
            [long]$codeOnlyGraph.counts.roots -eq 0 -and
            [long]$codeOnlyGraph.counts.nodes -eq 0 -and
            [long]$codeOnlyGraph.counts.edges -eq 0 -and
            [long]$codeOnlyGraph.counts.candidates -eq 0 -and
            [long]$codeOnlyGraph.counts.protocolSurfaces -eq 0 -and
            [long]$codeOnlyGraph.counts.parsedBlobs -eq 0 -and
            [long]$codeOnlyGraph.counts.parsedBlobBytes -eq 0 -and
            [long]$codeOnlyGraph.counts.pathInventoryUtf8Bytes -eq 0
        ) -Message 'TEST-0151 ordinary code-only tree did not produce one exact valid empty instruction graph.'

        $referencesTraversalFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = 'See [context](docs/context.md).'
            'docs/context.md' =
                'Required reading: [authority](authority.md).'
            'docs/authority.md' = 'Canonical project authority.'
        })
        $referencesTraversalGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $referencesTraversalFixture.Entries `
            -ReadBlob $referencesTraversalFixture.Reader
        Assert-True -Condition (
            @($referencesTraversalGraph.nodes.path) -ccontains
                'docs/authority.md' -and
            @($referencesTraversalGraph.edges | Where-Object {
                $_.source -ceq 'docs/context.md' -and
                $_.target -ceq 'docs/authority.md' -and
                $_.kind -ceq 'RequiresRead'
            }).Count -eq 1
        ) -Message 'TEST-0151 Required reading inside ordinary text reached through a References edge was not discovered transitively.'

        $regularTextFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = @'
Required reading: [memory](docs/MEMORY.rst).
Reference evidence: [manual](docs/source/manual.pdf).
'@
            'docs/MEMORY.rst' =
                'Required reading: [state](STATE).'
            'docs/STATE' =
                'Required reading: [leaf](leaf.md).'
            'docs/leaf.md' = 'Canonical project state.'
            'docs/source/manual.pdf' = 'Protected binary source evidence.'
        })
        $regularTextReads = [Collections.Generic.HashSet[string]]::new(
            [StringComparer]::Ordinal
        )
        $regularTextBaseReader = $regularTextFixture.Reader
        $regularTextReader = {
            param($entry)
            [void]$regularTextReads.Add([string]$entry.Path)
            [byte[]]$content = & $regularTextBaseReader $entry
            return ,$content
        }.GetNewClosure()
        $regularTextGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $regularTextFixture.Entries `
            -ReadBlob $regularTextReader
        Assert-True -Condition (
            @($regularTextGraph.nodes | Where-Object {
                $_.path -ceq 'docs/MEMORY.rst' -and
                $_.role -ceq 'ReferencedText'
            }).Count -eq 1 -and
            @($regularTextGraph.edges | Where-Object {
                $_.source -ceq 'docs/MEMORY.rst' -and
                $_.target -ceq 'docs/STATE' -and
                $_.kind -ceq 'RequiresRead'
            }).Count -eq 1
        ) -Message 'TEST-0151 a required regular .rst text target was not parsed transitively.'
        Assert-True -Condition (
            @($regularTextGraph.nodes | Where-Object {
                $_.path -ceq 'docs/STATE' -and
                $_.role -ceq 'ReferencedText'
            }).Count -eq 1 -and
            @($regularTextGraph.nodes.path) -ccontains 'docs/leaf.md' -and
            @($regularTextGraph.edges | Where-Object {
                $_.source -ceq 'docs/STATE' -and
                $_.target -ceq 'docs/leaf.md' -and
                $_.kind -ceq 'RequiresRead'
            }).Count -eq 1
        ) -Message 'TEST-0151 a required regular extensionless text target was not parsed transitively.'
        Assert-True -Condition (
            @($regularTextGraph.nodes | Where-Object {
                $_.path -ceq 'docs/source/manual.pdf' -and
                $_.role -ceq 'ProtectedNonText'
            }).Count -eq 1 -and
            -not $regularTextReads.Contains('docs/source/manual.pdf')
        ) -Message 'TEST-0151 an ordinary linked PDF was opened or promoted from protected evidence.'
        $protectedTokenFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = @'
Reference evidence: docs/source/plain.pdf
Reference evidence: `docs/source/code.pdf`.
'@
            'docs/source/plain.pdf' = 'Plain protected evidence.'
            'docs/source/code.pdf' = 'Code-span protected evidence.'
        })
        $protectedTokenReads = [Collections.Generic.HashSet[string]]::new(
            [StringComparer]::Ordinal
        )
        $protectedTokenBaseReader = $protectedTokenFixture.Reader
        $protectedTokenReader = {
            param($entry)
            [void]$protectedTokenReads.Add([string]$entry.Path)
            [byte[]]$content = & $protectedTokenBaseReader $entry
            return ,$content
        }.GetNewClosure()
        $protectedTokenGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $protectedTokenFixture.Entries `
            -ReadBlob $protectedTokenReader
        foreach ($protectedTokenPath in @(
            'docs/source/plain.pdf', 'docs/source/code.pdf'
        )) {
            Assert-True -Condition (
                @($protectedTokenGraph.nodes | Where-Object {
                    $_.path -ceq $protectedTokenPath -and
                    $_.role -ceq 'ProtectedNonText'
                }).Count -eq 1 -and
                @($protectedTokenGraph.edges | Where-Object {
                    $_.target -ceq $protectedTokenPath -and
                    $_.kind -ceq 'References' -and
                    $_.reason -ceq 'RepositoryPathToken'
                }).Count -eq 1 -and
                -not $protectedTokenReads.Contains($protectedTokenPath)
            ) -Message "TEST-0151 ordinary repository-path token '$protectedTokenPath' was not retained as unopened protected evidence."
        }
        foreach ($requiredProtectedLine in @(
            'Required reading: docs/source/required.pdf',
            'Required reading: `docs/source/required.pdf`'
        )) {
            $requiredProtectedFixture = New-TestGraphFixture -Files ([ordered]@{
                'AGENTS.md' = $requiredProtectedLine
                'docs/source/required.pdf' = 'Required protected evidence.'
            })
            Assert-ThrowsLike -Action {
                & $graphBuilder -BaseHead ('0' * 40) `
                    -TreeEntries $requiredProtectedFixture.Entries `
                    -ReadBlob $requiredProtectedFixture.Reader
            } -Pattern '*protected source or binary target*live instruction authority*' `
                -Message "TEST-0152 significant protected repository-path token '$requiredProtectedLine' did not fail closed."
        }
        foreach ($unsupportedRequiredLine in @(
            'See [custom](docs/MEMORY.custom).',
            'Required reading: [custom](docs/MEMORY.custom).',
            'Canonical authority: [custom](docs/MEMORY.custom).',
            'See docs/MEMORY.custom for context.',
            'See `docs/MEMORY.custom` for context.',
            'Required reading: POLICY.CUSTOM',
            'Required reading: `POLICY.CUSTOM`'
        )) {
            $unsupportedPath = if ($unsupportedRequiredLine.Contains(
                    'POLICY.CUSTOM')) {
                'POLICY.CUSTOM'
            }
            else { 'docs/MEMORY.custom' }
            $unsupportedRegularFixture = New-TestGraphFixture -Files ([ordered]@{
                'AGENTS.md' = $unsupportedRequiredLine
                $unsupportedPath = 'Consumer-specific text authority.'
            })
            Assert-ThrowsLike -Action {
                & $graphBuilder -BaseHead ('0' * 40) `
                    -TreeEntries $unsupportedRegularFixture.Entries `
                    -ReadBlob $unsupportedRegularFixture.Reader
            } -Pattern '*unsupported*text*' `
                -Message "TEST-0151 graph edge silently accepted unknown regular text '$unsupportedRequiredLine'."
        }

        $unicodeRawPath = 'docs/y' + [char]0x00F6 + 'nerge.md'
        $unicodeSpacedPath =
            'docs/ba' + [char]0x015F + 'ka y' + [char]0x00F6 + 'nerge.md'
        $flatSpacedPath = 'my policy.md'
        $spacedDirectoryPath = 'my docs/policy.md'
        $customPathFiles = [ordered]@{
            'AGENTS.md' =
                "Required reading: $unicodeRawPath.`n" +
                "Required reading: ``$unicodeSpacedPath``.`n" +
                "Required reading: ``$flatSpacedPath``.`n" +
                "Required reading: ``$spacedDirectoryPath``."
        }
        $customPathFiles[$unicodeRawPath] = 'Unicode raw-path authority.'
        $customPathFiles[$unicodeSpacedPath] =
            'Unicode spaced code-span authority.'
        $customPathFiles[$flatSpacedPath] = 'Flat spaced code-span authority.'
        $customPathFiles[$spacedDirectoryPath] =
            'Spaced-directory code-span authority.'
        $customPathFixture = New-TestGraphFixture -Files $customPathFiles
        $customPathGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $customPathFixture.Entries `
            -ReadBlob $customPathFixture.Reader
        foreach ($customPath in @(
            $unicodeRawPath, $unicodeSpacedPath,
            $flatSpacedPath, $spacedDirectoryPath
        )) {
            Assert-True -Condition (
                @($customPathGraph.edges | Where-Object {
                    $_.source -ceq 'AGENTS.md' -and
                    $_.target -ceq $customPath -and
                    $_.kind -ceq 'RequiresRead' -and
                    $_.reason -ceq 'RepositoryPathToken'
                }).Count -eq 1
            ) -Message "TEST-0151 Unicode or spaced consumer path '$customPath' was omitted."
        }

        $authorityOrderFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = @'
The canonical authority for project memory is docs/MEMORY.md.
The source of truth for task state is docs/TASKS.md.
Project memory authoritative source: docs/PROJECT.md
docs/CANONICAL_SOURCE.md is the canonical source.
docs/PRODUCT_CATALOG.md is the canonical product catalog.
The authoritative feature tracker is docs/FEATURE_TRACKER.md.
| Evidence | Full retains canonical authority; run tests/protocol.tests.ps1. |
This historical note is non-authoritative; see docs/HISTORICAL.md.
'@
            'docs/MEMORY.md' = 'Memory authority.'
            'docs/TASKS.md' = 'Task authority.'
            'docs/PROJECT.md' = 'Project authority.'
            'docs/CANONICAL_SOURCE.md' = 'Canonical source authority.'
            'docs/PRODUCT_CATALOG.md' = 'Canonical product catalog.'
            'docs/FEATURE_TRACKER.md' = 'Authoritative feature tracker.'
            'tests/protocol.tests.ps1' = 'Protected test implementation.'
            'docs/HISTORICAL.md' = 'Historical context.'
        })
        $authorityOrderGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $authorityOrderFixture.Entries `
            -ReadBlob $authorityOrderFixture.Reader
        foreach ($authorityPath in @(
            'docs/MEMORY.md', 'docs/TASKS.md', 'docs/PROJECT.md',
            'docs/CANONICAL_SOURCE.md'
        )) {
            Assert-True -Condition (
                @($authorityOrderGraph.edges | Where-Object {
                    $_.target -ceq $authorityPath -and
                    $_.kind -ceq 'DeclaresAuthority'
                }).Count -eq 1
            ) -Message "TEST-0151 authority word order hid '$authorityPath'."
        }
        foreach ($indexPath in @(
            'docs/PRODUCT_CATALOG.md', 'docs/FEATURE_TRACKER.md'
        )) {
            Assert-True -Condition (
                @($authorityOrderGraph.edges | Where-Object {
                    $_.target -ceq $indexPath -and $_.kind -ceq 'Indexes'
                }).Count -eq 1
            ) -Message "TEST-0151 index/catalog/tracker word order hid '$indexPath'."
        }
        Assert-True -Condition (
            @($authorityOrderGraph.edges | Where-Object {
                $_.target -ceq 'tests/protocol.tests.ps1' -and
                $_.kind -ceq 'References'
            }).Count -eq 1 -and
            @($authorityOrderGraph.edges | Where-Object {
                $_.target -ceq 'docs/HISTORICAL.md' -and
                $_.kind -ceq 'References'
            }).Count -eq 1
        ) -Message 'TEST-0151 table evidence or non-authoritative prose was promoted to live authority.'

        $flatRawFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = @'
Required reading: ROOT_MEMORY.md
Canonical authority: PROJECT_AUTHORITY.md
Required reading: `MEMORY`
Use `build` for local compilation.
'@
            'ROOT_MEMORY.md' = 'Project-specific memory.'
            'PROJECT_AUTHORITY.md' = 'Project-specific authority.'
            'MEMORY' = 'Extensionless project-specific memory.'
            'build' = 'Benign local command name.'
        })
        $flatRawGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $flatRawFixture.Entries `
            -ReadBlob $flatRawFixture.Reader
        Assert-True -Condition (
            @($flatRawGraph.edges | Where-Object {
                $_.source -ceq 'AGENTS.md' -and
                $_.target -ceq 'ROOT_MEMORY.md' -and
                $_.kind -ceq 'RequiresRead' -and
                $_.reason -ceq 'RepositoryPathToken'
            }).Count -eq 1 -and
            @($flatRawGraph.edges | Where-Object {
                $_.source -ceq 'AGENTS.md' -and
                $_.target -ceq 'PROJECT_AUTHORITY.md' -and
                $_.kind -ceq 'DeclaresAuthority' -and
                $_.reason -ceq 'RepositoryPathToken'
            }).Count -eq 1 -and
            @($flatRawGraph.edges | Where-Object {
                $_.source -ceq 'AGENTS.md' -and
                $_.target -ceq 'MEMORY' -and
                $_.kind -ceq 'RequiresRead' -and
                $_.reason -ceq 'RepositoryPathToken'
            }).Count -eq 1 -and
            @($flatRawGraph.nodes.path) -cnotcontains 'build'
        ) -Message 'TEST-0151 flat root filename or required extensionless code-span token handling was incomplete.'

        $imperativeReadingFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = @'
Before planning or editing, read these project memory files first:
- `ai/WORK_INDEX.md`
- `ai/SESSION_HANDOFF.md`

Then open only the routing files relevant to the task:
- `ai/PROJECT_STATE.md`

Do not open these files:
- `ai/NEGATED.md`

The helper can open files for display:
- `ai/BENIGN.md`

You must read the following project files:
- `ai/MUST_READ.md`

For each task, consult these routing documents:
- `ai/EACH_TASK.md`
'@
            'ai/WORK_INDEX.md' = 'Work routing authority.'
            'ai/SESSION_HANDOFF.md' = 'Session handoff authority.'
            'ai/PROJECT_STATE.md' = 'Project state authority.'
            'ai/NEGATED.md' = 'Negated reading example.'
            'ai/BENIGN.md' = 'Benign prose example.'
            'ai/MUST_READ.md' = 'Explicit must-read authority.'
            'ai/EACH_TASK.md' = 'Per-task routing authority.'
        })
        $imperativeReadingGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $imperativeReadingFixture.Entries `
            -ReadBlob $imperativeReadingFixture.Reader
        foreach ($requiredImperativePath in @(
            'ai/WORK_INDEX.md', 'ai/SESSION_HANDOFF.md',
            'ai/PROJECT_STATE.md', 'ai/MUST_READ.md', 'ai/EACH_TASK.md'
        )) {
            Assert-True -Condition (
                @($imperativeReadingGraph.edges | Where-Object {
                    $_.target -ceq $requiredImperativePath -and
                    $_.kind -ceq 'RequiresRead'
                }).Count -eq 1
            ) -Message "TEST-0151 imperative reading list hid '$requiredImperativePath'."
        }
        Assert-True -Condition (
            @($imperativeReadingGraph.edges | Where-Object {
                $_.target -cin @('ai/NEGATED.md', 'ai/BENIGN.md') -and
                $_.kind -cin @(
                    'RequiresRead', 'DeclaresAuthority', 'Indexes'
                )
            }).Count -eq 0
        ) -Message 'TEST-0151 negated or benign file-list prose became live authority.'

        $benignDottedTokenFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = @'
Release v0.12.6 remains supported.
Connect to 127.0.0.1 and retain threshold 1.25.
Finding `FIND-0001` uses tool `build.exe`.
'@
            'v0.12.6' = 'A coincidental numeric dotted filename.'
            '127.0.0.1' = 'A coincidental numeric dotted filename.'
            '1.25' = 'A coincidental numeric dotted filename.'
        })
        $benignDottedTokenGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $benignDottedTokenFixture.Entries `
            -ReadBlob $benignDottedTokenFixture.Reader
        Assert-True -Condition (
            @($benignDottedTokenGraph.nodes).Count -eq 1 -and
            @($benignDottedTokenGraph.edges).Count -eq 0
        ) -Message 'TEST-0151 benign version, finding, or command tokens created tracked authority evidence.'

        $referenceFormsFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = @'
Required reading: [full][memory-full].
Required reading: [collapsed][].
Required reading: [shortcut].
This [ordinary bracket] is not a reference.

[memory-full]: docs/FULL.md
[collapsed]: docs/COLLAPSED.md
[shortcut]: docs/SHORTCUT.md
'@
            'docs/FULL.md' = 'Full reference authority.'
            'docs/COLLAPSED.md' = 'Collapsed reference authority.'
            'docs/SHORTCUT.md' = 'Shortcut reference authority.'
        })
        $referenceFormsGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $referenceFormsFixture.Entries `
            -ReadBlob $referenceFormsFixture.Reader
        foreach ($referenceTarget in @(
            'docs/FULL.md', 'docs/COLLAPSED.md', 'docs/SHORTCUT.md'
        )) {
            Assert-True -Condition (
                @($referenceFormsGraph.edges | Where-Object {
                    $_.source -ceq 'AGENTS.md' -and
                    $_.target -ceq $referenceTarget -and
                    $_.kind -ceq 'RequiresRead' -and
                    $_.reason -ceq 'MarkdownReferenceLink'
                }).Count -eq 1
            ) -Message "TEST-0151 reference-style form for '$referenceTarget' was omitted."
        }
        Assert-True -Condition (
            @($referenceFormsGraph.nodes.path | Where-Object {
                $_ -like '*ordinary*' -or $_ -like '*bracket*'
            }).Count -eq 0
        ) -Message 'TEST-0151 benign unmatched bracket prose created a reference edge.'

        $inlineCodeExampleFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = @'
Required reading examples: `[fake](docs/FAKE.md)` and `[fake-ref][ref]`.
Required reading output from `git log v1.2.3`.
Required reading: `pwsh -File scripts/run.ps1`.
Required reading: `FIND-0001.md example`.
Required reading can be produced with `cat README.md`.
Required reading: `cat README.md`.
See `type README.md` for an example.
Required reading: `type README.md`.

[ref]: docs/FAKE-REF.md
'@
            'docs/FAKE.md' = 'Inline code example only.'
            'docs/FAKE-REF.md' = 'Inline reference-code example only.'
            'git log v1.2.3' = 'Command-shaped decoy.'
            'pwsh -File scripts/run.ps1' = 'Command-shaped decoy.'
            'FIND-0001.md example' = 'Finding-example decoy.'
            'cat README.md' = 'Command-shaped two-token decoy.'
            'type README.md' = 'Command-shaped two-token decoy.'
            'README.md' = 'A real file named by command arguments.'
        })
        $inlineCodeExampleGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $inlineCodeExampleFixture.Entries `
            -ReadBlob $inlineCodeExampleFixture.Reader
        Assert-True -Condition (
            @($inlineCodeExampleGraph.nodes.path) -cnotcontains
                'docs/FAKE.md' -and
            @($inlineCodeExampleGraph.nodes.path) -cnotcontains
                'docs/FAKE-REF.md' -and
            @($inlineCodeExampleGraph.nodes.path) -cnotcontains
                'git log v1.2.3' -and
            @($inlineCodeExampleGraph.nodes.path) -cnotcontains
                'pwsh -File scripts/run.ps1' -and
            @($inlineCodeExampleGraph.nodes.path) -cnotcontains
                'FIND-0001.md example' -and
            @($inlineCodeExampleGraph.nodes.path) -cnotcontains
                'cat README.md' -and
            @($inlineCodeExampleGraph.nodes.path) -cnotcontains
                'type README.md' -and
            @($inlineCodeExampleGraph.nodes.path) -cnotcontains
                'README.md' -and
            @($inlineCodeExampleGraph.edges).Count -eq 0
        ) -Message 'TEST-0151 Markdown, command, or finding syntax inside inline code created graph edges.'

        $uppercaseRawFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = 'Required reading: docs/UPPER.MD'
            'docs/UPPER.MD' = 'Uppercase extension authority.'
        })
        $uppercaseRawGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $uppercaseRawFixture.Entries `
            -ReadBlob $uppercaseRawFixture.Reader
        Assert-True -Condition (
            @($uppercaseRawGraph.nodes.path) -ccontains 'docs/UPPER.MD' -and
            @($uppercaseRawGraph.edges | Where-Object {
                $_.source -ceq 'AGENTS.md' -and
                $_.target -ceq 'docs/UPPER.MD' -and
                $_.kind -ceq 'RequiresRead' -and
                $_.reason -ceq 'RepositoryPathToken'
            }).Count -eq 1
        ) -Message 'TEST-0151 raw repository path with uppercase supported extension was not discovered.'

        $freshCultureChild = @'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version Latest
$culture = [Globalization.CultureInfo]::GetCultureInfo('__CULTURE__')
[Threading.Thread]::CurrentThread.CurrentCulture = $culture
[Threading.Thread]::CurrentThread.CurrentUICulture = $culture
$module = Import-Module '__MODULE__' -Force -PassThru
$utf8 = [Text.UTF8Encoding]::new($false)
function Get-ChildBlobSha {
    param([byte[]]$Bytes)
    $header = [Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
    $payload = [byte[]]::new($header.Length + $Bytes.Length)
    [Array]::Copy($header, 0, $payload, 0, $header.Length)
    [Array]::Copy($Bytes, 0, $payload, $header.Length, $Bytes.Length)
    $sha = [Security.Cryptography.SHA1]::Create()
    try {
        return ([BitConverter]::ToString(
            $sha.ComputeHash($payload)
        )).Replace('-', '').ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}
$files = [ordered]@{
    'AGENTS.md' = @"
REQUIRED READING: docs/REQUIRED.md.
PROJECT INDEX: docs/INDEX.md.
docs/AUTH.md IS THE AUTHORITATIVE SOURCE.
DO NOT READ docs/NEGATED.md.
"@
    'docs/REQUIRED.md' = 'Required authority.'
    'docs/INDEX.md' = 'Index authority.'
    'docs/AUTH.md' = 'Declared authority.'
    'docs/NEGATED.md' = 'Negated ordinary context.'
}
$blobs = @{}
$entries = [Collections.Generic.List[object]]::new()
foreach ($path in @($files.Keys)) {
    [byte[]]$bytes = $utf8.GetBytes([string]$files[$path])
    $blobs[[string]$path] = $bytes
    $entries.Add([pscustomobject]@{
        Path = [string]$path
        Mode = '100644'
        Type = 'blob'
        Sha = Get-ChildBlobSha -Bytes $bytes
    })
}
$reader = {
    param($entry)
    return ,([byte[]]$blobs[[string]$entry.Path])
}.GetNewClosure()
$graph = New-MeAndAIInstructionGraph -BaseHead ('0' * 40) `
    -TreeEntries @($entries) -ReadBlob $reader
$edgeKinds = @($graph.edges | ForEach-Object {
    "$([string]$_.target)|$([string]$_.kind)"
})
$result = [pscustomobject]@{
    digest = [string]$graph.digest
    edgeKinds = @($edgeKinds)
}
'RESULT=' + ($result | ConvertTo-Json -Depth 5 -Compress)
Remove-Module $module
'@
        $freshCultureResults = @{}
        $currentHostExecutable = (Get-Process -Id $PID).Path
        foreach ($cultureName in @('en-US', 'tr-TR')) {
            $child = $freshCultureChild.Replace('__CULTURE__', $cultureName).
                Replace('__MODULE__', $modulePath.Replace("'", "''"))
            $encodedChild = [Convert]::ToBase64String(
                [Text.Encoding]::Unicode.GetBytes($child)
            )
            $global:LASTEXITCODE = 0
            $childOutput = @(& $currentHostExecutable -NoLogo -NoProfile `
                -NonInteractive -EncodedCommand $encodedChild 2>&1 |
                ForEach-Object { [string]$_ })
            $childExitCode = $LASTEXITCODE
            $resultLines = @($childOutput | Where-Object {
                $_.StartsWith('RESULT=', [StringComparison]::Ordinal)
            })
            if ($childExitCode -ne 0 -or $resultLines.Count -ne 1) {
                Add-Failure "TEST-0151 fresh $cultureName culture graph failed: $($childOutput -join ' | ')"
                continue
            }
            $freshCultureResults[$cultureName] =
                $resultLines[0].Substring('RESULT='.Length) | ConvertFrom-Json
        }
        if ($freshCultureResults.Count -eq 2) {
            $expectedCultureEdges = @(
                'docs/AUTH.md|DeclaresAuthority',
                'docs/INDEX.md|Indexes',
                'docs/NEGATED.md|References',
                'docs/REQUIRED.md|RequiresRead'
            )
            foreach ($cultureName in @('en-US', 'tr-TR')) {
                Assert-SequenceEqual `
                    -Actual @($freshCultureResults[$cultureName].edgeKinds) `
                    -Expected $expectedCultureEdges `
                    -Message "TEST-0151 $cultureName semantic directive classification differs."
            }
            Assert-True -Condition (
                [string]$freshCultureResults['en-US'].digest -ceq
                    [string]$freshCultureResults['tr-TR'].digest
            ) -Message 'TEST-0151 semantic classification depends on process culture.'
        }

        $externalSchemeFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = @'
See [FTP evidence](ftp://example.invalid/evidence.md).
Required reading: [Git transport](git+ssh://example.invalid/project.git).
Consult [consumer scheme](consumer+memory:authority/root).
'@
        })
        $externalSchemeGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $externalSchemeFixture.Entries `
            -ReadBlob $externalSchemeFixture.Reader
        Assert-SequenceEqual -Actual @(
            $externalSchemeGraph.edges | Where-Object { [bool]$_.external } |
                ForEach-Object { [string]$_.target }
        ) -Expected @(
            'consumer+memory:authority/root',
            'ftp://example.invalid/evidence.md',
            'git+ssh://example.invalid/project.git'
        ) -Message 'TEST-0151 RFC absolute external schemes were rewritten as repository paths.'
        $fileUriFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = 'Required reading: [unsafe](file:///outside/MEMORY.md).'
        })
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('0' * 40) `
                -TreeEntries $fileUriFixture.Entries `
                -ReadBlob $fileUriFixture.Reader
        } -Pattern '*escapes the repository root*' `
            -Message 'TEST-0152 file URI was accepted as external evidence.'

        $hostLexicalPathFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = 'Required reading: [authority](docs/a|b.md).'
            'docs/a|b.md' = 'Git-valid host-independent authority.'
            'a|b/AGENTS.md' = 'Scoped consumer directives.'
        })
        $hostLexicalPathGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $hostLexicalPathFixture.Entries `
            -ReadBlob $hostLexicalPathFixture.Reader
        Assert-True -Condition (
            [bool](& $graphValidator -Graph $hostLexicalPathGraph) -and
            @($hostLexicalPathGraph.edges | Where-Object {
                $_.source -ceq 'AGENTS.md' -and
                $_.target -ceq 'docs/a|b.md' -and
                $_.kind -ceq 'RequiresRead'
            }).Count -eq 1 -and
            @($hostLexicalPathGraph.edges | Where-Object {
                $_.source -ceq 'AGENTS.md' -and
                $_.target -ceq 'a|b/AGENTS.md' -and
                $_.kind -ceq 'Scopes'
            }).Count -eq 1
        ) -Message 'TEST-0151 Git path classification depends on host IO.Path rules.'

        $periodMissingFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = 'Required reading: docs/MISSING.md.'
        })
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('0' * 40) `
                -TreeEntries $periodMissingFixture.Entries `
                -ReadBlob $periodMissingFixture.Reader
        } -Pattern '*required instruction target*docs/MISSING.md*missing*' `
            -Message 'TEST-0152 terminal sentence punctuation hid a missing required target.'

        foreach ($unsafeRawPath in @(
            '/docs/x.md', 'C:/docs/x.md', 'docs\x.md',
            '../../../../docs/x.md'
        )) {
            $unsafeRawFixture = New-TestGraphFixture -Files ([ordered]@{
                'AGENTS.md' = "Required reading: $unsafeRawPath"
            })
            Assert-ThrowsLike -Action {
                & $graphBuilder -BaseHead ('0' * 40) `
                    -TreeEntries $unsafeRawFixture.Entries `
                    -ReadBlob $unsafeRawFixture.Reader
            } -Pattern '*escapes the repository root*' `
                -Message "TEST-0152 unsafe raw path '$unsafeRawPath' did not fail closed."
        }

        $encodedBackslashFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' =
                'Required reading: [bad](docs%5Cx.md).'
        })
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('0' * 40) `
                -TreeEntries $encodedBackslashFixture.Entries `
                -ReadBlob $encodedBackslashFixture.Reader
        } -Pattern '*escapes the repository root*' `
            -Message 'TEST-0152 percent-decoded Markdown backslash did not fail closed.'

        $nfcReferencePath = 'docs/caf' + [char]0x00E9 + '.md'
        $nfdReferencePath = 'docs/cafe' + [char]0x0301 + '.md'
        $nfdReferenceFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' =
                "Required reading: [authority]($nfdReferencePath)."
            $nfcReferencePath = 'One canonical NFC authority.'
        })
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('0' * 40) `
                -TreeEntries $nfdReferenceFixture.Entries `
                -ReadBlob $nfdReferenceFixture.Reader
        } -Pattern '*noncanonical Unicode normalization*' `
            -Message 'TEST-0152 NFD reference silently resolved to a distinct NFC tree path.'

        Assert-True -Condition (
            -not (& $canonicalPathValidator -Path 'C:/docs/x.md') -and
            -not (& $canonicalPathValidator -Path 'c:docs/x.md')
        ) -Message 'TEST-0152 canonical repository path predicate accepted a drive prefix on this host.'

        $multilineReferenceText = @(
            '# Consumer instructions',
            '',
            'If `.ai/adoption/meandai-capabilities.json` exists, treat it as an active handoff.',
            'Read the [common protocol](.ai/protocol/PROTOCOL.md).'
        ) -join "`n"
        $emptyReferenceInventory =
            [Collections.Generic.Dictionary[string, object]]::new(
                [StringComparer]::Ordinal
            )
        $multilineReferences = @(& $policyModule {
            param($text, $inventory)
            Get-MeAndAIInstructionGraphReferences -SourcePath 'AGENTS.md' `
                -Text $text -RepositoryPathInventory $inventory
        } $multilineReferenceText $emptyReferenceInventory)
        Assert-True -Condition (
            $multilineReferences.Count -eq 2 -and
            @($multilineReferences | Where-Object {
                $_.target -ceq '.ai/adoption/meandai-capabilities.json' -and
                $_.kind -ceq 'References' -and $_.anchor -ceq 'L3' -and
                $_.reason -ceq 'RepositoryPathToken' -and
                -not [bool]$_.required -and -not [bool]$_.external
            }).Count -eq 1 -and
            @($multilineReferences | Where-Object {
                $_.target -ceq '.ai/protocol/PROTOCOL.md' -and
                $_.kind -ceq 'RequiresRead' -and $_.anchor -ceq 'L4' -and
                $_.reason -ceq 'MarkdownLink' -and
                [bool]$_.required -and -not [bool]$_.external
            }).Count -eq 1
        ) -Message 'TEST-0151 multiline parsing merged conditional and required references across source lines.'

        $lineEndingUtf8 = [Text.UTF8Encoding]::new($false)
        $lineEndingCases = [ordered]@{
            LF = "`n"
            CRLF = "`r`n"
            CR = "`r"
            'BOM-LF' = "`n"
        }
        foreach ($lineEndingCase in @($lineEndingCases.Keys)) {
            $lineEnding = [string]$lineEndingCases[$lineEndingCase]
            $agentsBytes = $lineEndingUtf8.GetBytes((@(
                '# Instructions',
                '```text',
                'Required reading: docs/HIDDEN.md.',
                '```',
                'Required reading: docs/LIVE.md.'
            ) -join $lineEnding))
            if ($lineEndingCase -ceq 'BOM-LF') {
                $agentsBytes = [byte[]](@(0xEF, 0xBB, 0xBF) + $agentsBytes)
            }
            $lineEndingFixture = New-TestByteGraphFixture -Files ([ordered]@{
                'AGENTS.md' = [byte[]]$agentsBytes
                'docs/HIDDEN.md' = [byte[]]$lineEndingUtf8.GetBytes(
                    'Fenced example only.'
                )
                'docs/LIVE.md' = [byte[]]$lineEndingUtf8.GetBytes(
                    'Live authority.'
                )
            })
            $lineEndingGraph = & $graphBuilder -BaseHead ('0' * 40) `
                -TreeEntries $lineEndingFixture.Entries `
                -ReadBlob $lineEndingFixture.Reader
            Assert-True -Condition (
                @($lineEndingGraph.nodes.path) -cnotcontains
                    'docs/HIDDEN.md' -and
                @($lineEndingGraph.edges | Where-Object {
                    $_.target -ceq 'docs/LIVE.md' -and
                    $_.kind -ceq 'RequiresRead'
                }).Count -eq 1
            ) -Message "TEST-0151 $lineEndingCase line handling promoted fenced example text or hid live authority."
        }

        $referencedBomBytes = [byte[]](@(0xEF, 0xBB, 0xBF) +
            $lineEndingUtf8.GetBytes((@(
                '```text',
                'Required reading: docs/REFERENCED-HIDDEN.md.',
                '```',
                'Required reading: docs/REFERENCED-LIVE.md.'
            ) -join "`n")))
        $referencedBomFixture = New-TestByteGraphFixture -Files ([ordered]@{
            'AGENTS.md' = [byte[]]$lineEndingUtf8.GetBytes(
                'See [context](docs/context.md).'
            )
            'docs/context.md' = [byte[]]$referencedBomBytes
            'docs/REFERENCED-HIDDEN.md' = [byte[]]$lineEndingUtf8.GetBytes(
                'Fenced referenced example.'
            )
            'docs/REFERENCED-LIVE.md' = [byte[]]$lineEndingUtf8.GetBytes(
                'Referenced live authority.'
            )
        })
        $referencedBomGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $referencedBomFixture.Entries `
            -ReadBlob $referencedBomFixture.Reader
        Assert-True -Condition (
            @($referencedBomGraph.nodes.path) -cnotcontains
                'docs/REFERENCED-HIDDEN.md' -and
            @($referencedBomGraph.edges | Where-Object {
                $_.source -ceq 'docs/context.md' -and
                $_.target -ceq 'docs/REFERENCED-LIVE.md' -and
                $_.kind -ceq 'RequiresRead'
            }).Count -eq 1
        ) -Message 'TEST-0151 a BOM in referenced instruction text corrupted fence state.'

        $longFenceFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = @'
# Instructions

````text
```
Required reading: [hidden](docs/HIDDEN.md).
````
Required reading: [live](docs/LIVE.md).
'@
            'docs/HIDDEN.md' = 'Fenced example only.'
            'docs/LIVE.md' = 'Live required authority.'
        })
        $longFenceGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $longFenceFixture.Entries `
            -ReadBlob $longFenceFixture.Reader
        Assert-True -Condition (
            @($longFenceGraph.nodes.path) -cnotcontains 'docs/HIDDEN.md' -and
            @($longFenceGraph.nodes.path) -ccontains 'docs/LIVE.md'
        ) -Message 'TEST-0151 a shorter fence closed a four-backtick block or the live required edge after its real close was lost.'

        $trailingFenceFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = @'
# Instructions

````text
```` trailing-non-space-text
Required reading: [hidden](docs/TRAILING-HIDDEN.md).
````
Required reading: [live](docs/TRAILING-LIVE.md).
'@
            'docs/TRAILING-HIDDEN.md' = 'Still fenced example only.'
            'docs/TRAILING-LIVE.md' = 'Live required authority.'
        })
        $trailingFenceGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $trailingFenceFixture.Entries `
            -ReadBlob $trailingFenceFixture.Reader
        Assert-True -Condition (
            @($trailingFenceGraph.nodes.path) -cnotcontains
                'docs/TRAILING-HIDDEN.md' -and
            @($trailingFenceGraph.nodes.path) -ccontains
                'docs/TRAILING-LIVE.md'
        ) -Message 'TEST-0151 trailing non-space text closed a fence or hid the live required edge after the valid close.'

        $invalidBacktickInfoFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = @'
# Instructions

``` bad`info
Required reading: [live](docs/INVALID-INFO-LIVE.md).
```
'@
            'docs/INVALID-INFO-LIVE.md' = 'Live required authority.'
        })
        $invalidBacktickInfoGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $invalidBacktickInfoFixture.Entries `
            -ReadBlob $invalidBacktickInfoFixture.Reader
        Assert-True -Condition (
            @($invalidBacktickInfoGraph.nodes.path) -ccontains
                'docs/INVALID-INFO-LIVE.md'
        ) -Message 'TEST-0151 an invalid backtick-info opener hid a live required reference.'

        $treeShapeFixture = New-TestGraphFixture -Files ([ordered]@{
            '.github/instructions/nested/live.md' = 'Scoped instructions.'
            '.github/instructions/nested/image.png' = 'not opened'
        }) -SpecialEntries @{
            '.github' = [pscustomobject]@{
                Mode = '040000'; Type = 'tree'; Sha = ('1' * 40)
            }
            '.github/instructions' = [pscustomobject]@{
                Mode = '040000'; Type = 'tree'; Sha = ('2' * 40)
            }
            '.github/instructions/nested' = [pscustomobject]@{
                Mode = '040000'; Type = 'tree'; Sha = ('3' * 40)
            }
        }
        $treeShapeInnerReader = $treeShapeFixture.Reader
        $treeShapeOpenedPaths =
            [System.Collections.Generic.List[string]]::new()
        $treeShapeReader = {
            param($entry)
            $treeShapeOpenedPaths.Add([string]$entry.Path)
            [byte[]]$result = & $treeShapeInnerReader $entry
            return ,$result
        }.GetNewClosure()
        $treeShapeGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $treeShapeFixture.Entries -ReadBlob $treeShapeReader
        Assert-True -Condition (
            @($treeShapeGraph.roots.path) -ccontains
                '.github/instructions/nested/live.md'
        ) -Message 'TEST-0152 ls-tree -t supported nested Markdown blob was not an instruction root.'
        Assert-True -Condition (
            @($treeShapeGraph.roots.path) -cnotcontains
                '.github/instructions/nested'
        ) -Message 'TEST-0152 ls-tree -t intermediate tree became an instruction root.'
        Assert-True -Condition (
            @($treeShapeGraph.nodes | Where-Object {
                $_.path -ceq '.github/instructions/nested/image.png' -and
                $_.role -ceq 'InstructionRoot'
            }).Count -eq 0 -and
            @($treeShapeGraph.nodes | Where-Object {
                $_.path -ceq '.github/instructions/nested/image.png' -and
                $_.role -ceq 'UnlinkedKnownSurfaceCandidate'
            }).Count -eq 1 -and
            @($treeShapeGraph.protocolSurfaces) -ccontains
                '.github/instructions/nested/image.png'
        ) -Message 'TEST-0152 ls-tree -t unsupported PNG did not retain compatibility-candidate-only semantics.'
        Assert-True -Condition (
            (@($treeShapeOpenedPaths) -join ',') -ceq
                '.github/instructions/nested/live.md'
        ) -Message 'TEST-0152 ls-tree -t traversal opened an intermediate tree or unsupported PNG blob.'

        $linkedRootFixture = New-TestGraphFixture -Files @{} `
            -SpecialEntries @{
                '.github/instructions/nested' = [pscustomobject]@{
                    Mode = '040000'; Type = 'tree'; Sha = ('4' * 40)
                }
                '.github/instructions/nested/linked.md' = [pscustomobject]@{
                    Mode = '120000'; Type = 'blob'; Sha = ('5' * 40)
                }
            }
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('0' * 40) `
                -TreeEntries $linkedRootFixture.Entries `
                -ReadBlob $linkedRootFixture.Reader
        } -Pattern '*Instruction root*not one regular blob*' `
            -Message 'TEST-0152 supported instruction-root symlink did not fail closed with ls-tree -t entries.'

        $rootWithoutNode = Copy-TestInstructionGraph -Graph $graph
        $rootWithoutNode.roots[0].path = '000-NOT-A-NODE.md'
        $rootWithoutNode.roots = @(Sort-TestInstructionGraphRoots `
            -Roots @($rootWithoutNode.roots))
        Set-TestInstructionGraphDigest -Graph $rootWithoutNode `
            -PolicyModule $policyModule
        Assert-True -Condition (-not (& $graphValidator `
            -Graph $rootWithoutNode)) `
            -Message 'TEST-0151 exact validator accepted a recomputed-digest root whose path is not a graph node.'

        $edgeWithoutSource = Copy-TestInstructionGraph -Graph $graph
        $edgeWithoutSource.edges[0].source = '000-NOT-A-NODE.md'
        $edgeWithoutSource.edges = @(Sort-TestInstructionGraphEdges `
            -Edges @($edgeWithoutSource.edges))
        Set-TestInstructionGraphDigest -Graph $edgeWithoutSource `
            -PolicyModule $policyModule
        Assert-True -Condition (-not (& $graphValidator `
            -Graph $edgeWithoutSource)) `
            -Message 'TEST-0151 exact validator accepted a recomputed-digest edge whose source is not a graph node.'

        $edgeWithoutTarget = Copy-TestInstructionGraph -Graph $graph
        $localEdge = @($edgeWithoutTarget.edges | Where-Object {
            -not [bool]$_.external
        } | Select-Object -First 1)[0]
        $localEdge.target = 'zzzz/NOT-A-NODE.md'
        $edgeWithoutTarget.edges = @(Sort-TestInstructionGraphEdges `
            -Edges @($edgeWithoutTarget.edges))
        Set-TestInstructionGraphDigest -Graph $edgeWithoutTarget `
            -PolicyModule $policyModule
        Assert-True -Condition (-not (& $graphValidator `
            -Graph $edgeWithoutTarget)) `
            -Message 'TEST-0151 exact validator accepted a recomputed-digest ordinary local edge whose target is not a graph node.'

        $duplicateSemanticEdge = Copy-TestInstructionGraph -Graph $graph
        $duplicateEdge = $duplicateSemanticEdge.edges[0] |
            ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $duplicateEdge.anchor = [string]$duplicateEdge.anchor + '#duplicate'
        $duplicateEdge.reason = [string]$duplicateEdge.reason + 'Duplicate'
        $duplicateSemanticEdge.edges = @(Sort-TestInstructionGraphEdges `
            -Edges (@($duplicateSemanticEdge.edges) + @($duplicateEdge)))
        $duplicateSemanticEdge.counts.edges =
            @($duplicateSemanticEdge.edges).Count
        Set-TestInstructionGraphDigest -Graph $duplicateSemanticEdge `
            -PolicyModule $policyModule
        Assert-True -Condition (-not (& $graphValidator `
            -Graph $duplicateSemanticEdge)) `
            -Message 'TEST-0151 exact validator accepted a recomputed-digest duplicate semantic edge with different anchor/reason text.'

        $nodeWithUndeclaredScope = Copy-TestInstructionGraph -Graph $graph
        $scopedNode = @($nodeWithUndeclaredScope.nodes | Where-Object {
            [string]$_.role -ceq 'ReferencedText'
        } | Select-Object -First 1)[0]
        $scopedNode.scope = 'zzzz/NOT-AN-INSTRUCTION-ROOT.md'
        Set-TestInstructionGraphDigest -Graph $nodeWithUndeclaredScope `
            -PolicyModule $policyModule
        Assert-True -Condition (-not (& $graphValidator `
            -Graph $nodeWithUndeclaredScope)) `
            -Message 'TEST-0151 exact validator accepted a recomputed-digest node whose scope is not a declared instruction root.'

        $wrongSurfaceProjection = Copy-TestInstructionGraph -Graph $graph
        $wrongSurfaces = @($wrongSurfaceProjection.protocolSurfaces) +
            @('zzzz/NOT-A-NODE.md')
        [Array]::Sort($wrongSurfaces, [StringComparer]::Ordinal)
        $wrongSurfaceProjection.protocolSurfaces = @($wrongSurfaces)
        $wrongSurfaceProjection.counts.protocolSurfaces =
            @($wrongSurfaces).Count
        Set-TestInstructionGraphDigest -Graph $wrongSurfaceProjection `
            -PolicyModule $policyModule
        Assert-True -Condition (-not (& $graphValidator `
            -Graph $wrongSurfaceProjection)) `
            -Message 'TEST-0151 exact validator accepted a recomputed-digest surface projection not derived from graph roots/nodes.'

        foreach ($typeDrift in @(
            [pscustomobject]@{ Area = 'schema'; Property = 'schema' },
            [pscustomobject]@{ Area = 'limits'; Property = 'maximumNodes' },
            [pscustomobject]@{ Area = 'counts'; Property = 'nodes' }
        )) {
            $numericStringGraph = Copy-TestInstructionGraph -Graph $graph
            if ([string]$typeDrift.Area -ceq 'schema') {
                $numericStringGraph.schema = [string]$numericStringGraph.schema
            }
            else {
                $container = $numericStringGraph.([string]$typeDrift.Area)
                $propertyName = [string]$typeDrift.Property
                $container.$propertyName = [string]$container.$propertyName
            }
            Set-TestInstructionGraphDigest -Graph $numericStringGraph `
                -PolicyModule $policyModule
            Assert-True -Condition (-not (& $graphValidator `
                -Graph $numericStringGraph)) -Message (
                    'TEST-0151 exact validator accepted numeric-string type ' +
                    "drift in $([string]$typeDrift.Area).$([string]$typeDrift.Property)."
                )
        }

        foreach ($reasonRole in @(
            'InstructionRoot', 'ReferencedText',
            'UnlinkedKnownSurfaceCandidate'
        )) {
            $reasonDriftGraph = Copy-TestInstructionGraph -Graph $graph
            $reasonDriftNode = @($reasonDriftGraph.nodes | Where-Object {
                [string]$_.role -ceq $reasonRole
            } | Select-Object -First 1)[0]
            $reasonDriftNode.reasons = @('MadeUpReason')
            Set-TestInstructionGraphDigest -Graph $reasonDriftGraph `
                -PolicyModule $policyModule
            Assert-True -Condition (-not (& $graphValidator `
                -Graph $reasonDriftGraph)) -Message (
                    'TEST-0151 exact validator accepted fabricated discovery ' +
                    "reasons for role '$reasonRole'."
                )
        }

        $orphanCandidateGraph = Copy-TestInstructionGraph -Graph $graph
        $orphanCandidatePath = 'totally/custom.xyz'
        $orphanCandidateGraph.nodes = @(
            Sort-TestInstructionGraphPathRecords -Records @(
                @($orphanCandidateGraph.nodes) + @(
                    [pscustomobject][ordered]@{
                        path = $orphanCandidatePath
                        mode = '100644'
                        type = 'blob'
                        blobSha = 'f' * 40
                        scope = ''
                        role = 'UnlinkedKnownSurfaceCandidate'
                        reasons = @('KnownSurfaceCompatibility')
                    }
                )
            )
        )
        $orphanCandidates = @($orphanCandidateGraph.candidates) +
            @($orphanCandidatePath)
        [Array]::Sort($orphanCandidates, [StringComparer]::Ordinal)
        $orphanCandidateGraph.candidates = @($orphanCandidates)
        $orphanSurfaces = @($orphanCandidateGraph.protocolSurfaces) +
            @($orphanCandidatePath)
        [Array]::Sort($orphanSurfaces, [StringComparer]::Ordinal)
        $orphanCandidateGraph.protocolSurfaces = @($orphanSurfaces)
        $orphanCandidateGraph.counts.treeEntries =
            [long]$orphanCandidateGraph.counts.treeEntries + 1
        $orphanCandidateGraph.counts.treePathUtf8Bytes =
            [long]$orphanCandidateGraph.counts.treePathUtf8Bytes +
            [Text.Encoding]::UTF8.GetByteCount($orphanCandidatePath)
        $orphanCandidateGraph.counts.nodes =
            @($orphanCandidateGraph.nodes).Count
        $orphanCandidateGraph.counts.candidates =
            @($orphanCandidateGraph.candidates).Count
        $orphanCandidateGraph.counts.protocolSurfaces =
            @($orphanCandidateGraph.protocolSurfaces).Count
        $orphanCandidateGraph.counts.pathInventoryUtf8Bytes =
            [Text.Encoding]::UTF8.GetByteCount(
                (@($orphanCandidateGraph.nodes.path) -join "`n")
            )
        Set-TestInstructionGraphDigest -Graph $orphanCandidateGraph `
            -PolicyModule $policyModule
        Assert-True -Condition (-not (& $graphValidator `
            -Graph $orphanCandidateGraph)) `
            -Message 'TEST-0151 exact validator accepted an orphan compatibility candidate without a matching seed root.'

        $orphanProtectedGraph = Copy-TestInstructionGraph -Graph $graph
        $orphanProtectedPath = 'evidence/orphan.pdf'
        $orphanProtectedGraph.nodes = @(
            Sort-TestInstructionGraphPathRecords -Records @(
                @($orphanProtectedGraph.nodes) + @(
                    [pscustomobject][ordered]@{
                        path = $orphanProtectedPath
                        mode = '100644'
                        type = 'blob'
                        blobSha = 'e' * 40
                        scope = 'AGENTS.md'
                        role = 'ProtectedNonText'
                        reasons = @('References')
                    }
                )
            )
        )
        $orphanProtectedGraph.counts.treeEntries =
            [long]$orphanProtectedGraph.counts.treeEntries + 1
        $orphanProtectedGraph.counts.treePathUtf8Bytes =
            [long]$orphanProtectedGraph.counts.treePathUtf8Bytes +
            [Text.Encoding]::UTF8.GetByteCount($orphanProtectedPath)
        $orphanProtectedGraph.counts.nodes =
            @($orphanProtectedGraph.nodes).Count
        $orphanProtectedGraph.counts.pathInventoryUtf8Bytes =
            [Text.Encoding]::UTF8.GetByteCount(
                (@($orphanProtectedGraph.nodes.path) -join "`n")
            )
        Set-TestInstructionGraphDigest -Graph $orphanProtectedGraph `
            -PolicyModule $policyModule
        Assert-True -Condition (-not (& $graphValidator `
            -Graph $orphanProtectedGraph)) `
            -Message 'TEST-0151 exact validator accepted an orphan protected terminal without incoming evidence.'

        $overBudgetPath = ('x' * (
            [int]$graph.limits.maximumPathUtf8Bytes + 1
        )) + '/AGENTS.md'
        $overBudgetPathBytes = [Text.Encoding]::UTF8.GetByteCount(
            $overBudgetPath
        )
        $overBudgetPathGraph = [pscustomobject][ordered]@{
            schema = [int]$graph.schema
            baseHead = '0' * 40
            limits = $graph.limits | ConvertTo-Json -Depth 5 | ConvertFrom-Json
            roots = @([pscustomobject][ordered]@{
                path = $overBudgetPath
                kind = 'ScopedAgents'
            })
            nodes = @([pscustomobject][ordered]@{
                path = $overBudgetPath
                mode = '100644'
                type = 'blob'
                blobSha = 'f' * 40
                scope = $overBudgetPath
                role = 'InstructionRoot'
                reasons = @('InstructionRootSeed')
            })
            edges = @()
            candidates = @()
            protocolSurfaces = @($overBudgetPath)
            counts = [pscustomobject][ordered]@{
                treeEntries = 1
                treePathUtf8Bytes = [long]$overBudgetPathBytes
                roots = 1
                nodes = 1
                edges = 0
                candidates = 0
                protocolSurfaces = 1
                parsedBlobs = 1
                parsedBlobBytes = 0
                pathInventoryUtf8Bytes = [int]$overBudgetPathBytes
            }
            digest = ''
        }
        Set-TestInstructionGraphDigest -Graph $overBudgetPathGraph `
            -PolicyModule $policyModule
        Assert-True -Condition (-not (& $graphValidator `
            -Graph $overBudgetPathGraph)) `
            -Message 'TEST-0151 exact validator accepted a recomputed-digest graph beyond the path-inventory budget.'

        $linkedInstructionRoot = Copy-TestInstructionGraph -Graph $graph
        $linkedRootNode = @($linkedInstructionRoot.nodes | Where-Object {
            [string]$_.role -ceq 'InstructionRoot'
        } | Select-Object -First 1)[0]
        $linkedRootNode.mode = '120000'
        Set-TestInstructionGraphDigest -Graph $linkedInstructionRoot `
            -PolicyModule $policyModule
        Assert-True -Condition (-not (& $graphValidator `
            -Graph $linkedInstructionRoot)) `
            -Message 'TEST-0151 exact validator accepted a symlink instruction root.'

        $depthRootNode = @($graph.nodes | Where-Object {
            $_.path -ceq 'AGENTS.md'
        })[0] | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $depthNodes = [Collections.Generic.List[object]]::new()
        $depthNodes.Add($depthRootNode)
        $depthEdges = [Collections.Generic.List[object]]::new()
        $depthSource = 'AGENTS.md'
        for ($depth = 0; $depth -le [int]$graph.limits.maximumDepth; $depth++) {
            $depthTarget = 'docs/depth-{0:d2}.md' -f $depth
            $depthNodes.Add([pscustomobject][ordered]@{
                path = $depthTarget
                mode = '100644'
                type = 'blob'
                blobSha = 'f' * 40
                scope = 'AGENTS.md'
                role = 'ReferencedText'
                reasons = @('References')
            })
            $depthEdges.Add([pscustomobject][ordered]@{
                source = $depthSource
                target = $depthTarget
                kind = 'References'
                anchor = 'L1'
                reason = 'MarkdownLink'
                external = $false
            })
            $depthSource = $depthTarget
        }
        $depthNodePaths = @($depthNodes | ForEach-Object {
            [string]$_.path
        })
        $depthPathBytes = [Text.Encoding]::UTF8.GetByteCount(
            ($depthNodePaths -join "`n")
        )
        $overDepthGraph = [pscustomobject][ordered]@{
            schema = [int]$graph.schema
            baseHead = '0' * 40
            limits = $graph.limits | ConvertTo-Json -Depth 5 | ConvertFrom-Json
            roots = @([pscustomobject][ordered]@{
                path = 'AGENTS.md'
                kind = 'ScopedAgents'
            })
            nodes = @($depthNodes)
            edges = @($depthEdges)
            candidates = @()
            protocolSurfaces = @($depthNodePaths)
            counts = [pscustomobject][ordered]@{
                treeEntries = [int]$depthNodes.Count
                treePathUtf8Bytes = [long]$depthPathBytes
                roots = 1
                nodes = [int]$depthNodes.Count
                edges = [int]$depthEdges.Count
                candidates = 0
                protocolSurfaces = [int]$depthNodes.Count
                parsedBlobs = [int]$depthNodes.Count
                parsedBlobBytes = 0
                pathInventoryUtf8Bytes = [int]$depthPathBytes
            }
            digest = ''
        }
        Set-TestInstructionGraphDigest -Graph $overDepthGraph `
            -PolicyModule $policyModule
        Assert-True -Condition (-not (& $graphValidator `
            -Graph $overDepthGraph)) `
            -Message 'TEST-0151 exact validator accepted a recomputed-digest graph beyond the traversal-depth budget.'

        $missingFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = 'Required reading: [missing](docs/MISSING.md).'
        })
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('b' * 40) `
                -TreeEntries $missingFixture.Entries `
                -ReadBlob $missingFixture.Reader
        } -Pattern '*required instruction target*missing*' `
            -Message 'TEST-0152 missing required target did not fail closed.'

        foreach ($missingSpacedDirective in @(
            'Required reading: `docs/missing memory.md`.',
            'Canonical source: `docs/missing authority.md`.'
        )) {
            $missingSpacedFixture = New-TestGraphFixture -Files ([ordered]@{
                'AGENTS.md' = $missingSpacedDirective
            })
            Assert-ThrowsLike -Action {
                & $graphBuilder -BaseHead ('b' * 40) `
                    -TreeEntries $missingSpacedFixture.Entries `
                    -ReadBlob $missingSpacedFixture.Reader
            } -Pattern '*required instruction target*missing*' `
                -Message "TEST-0152 significant spaced target '$missingSpacedDirective' did not fail closed when absent."
        }

        $escapeFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = 'Required reading: [escape](../outside.md).'
        })
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('c' * 40) `
                -TreeEntries $escapeFixture.Entries `
                -ReadBlob $escapeFixture.Reader
        } -Pattern '*escapes the repository root*' `
            -Message 'TEST-0152 repository escape did not fail closed.'

        $linkedFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = 'Required reading: [linked](docs/LINKED.md).'
        }) -SpecialEntries @{
            'docs/LINKED.md' = [pscustomobject]@{
                Mode = '120000'
                Type = 'blob'
                Sha = ('d' * 40)
            }
        }
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('d' * 40) `
                -TreeEntries $linkedFixture.Entries `
                -ReadBlob $linkedFixture.Reader
        } -Pattern '*non-regular instruction target*' `
            -Message 'TEST-0152 linked instruction target did not fail closed.'

        $reservedFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = 'Required reading: [protocol](.ai/protocol/PROTOCOL.md).'
        }) -SpecialEntries @{
            '.ai/protocol' = [pscustomobject]@{
                Mode = '160000'
                Type = 'commit'
                Sha = ('e' * 40)
            }
        }
        $reservedGraph = & $graphBuilder -BaseHead ('e' * 40) `
            -TreeEntries $reservedFixture.Entries `
            -ReadBlob $reservedFixture.Reader
        Assert-True -Condition (@($reservedGraph.nodes | Where-Object {
            $_.path -ceq '.ai/protocol' -and
            $_.mode -ceq '160000' -and $_.type -ceq 'commit' -and
            $_.role -ceq 'ProtectedNonText' -and
            @($_.reasons) -ccontains 'ReservedIntegrationTerminal'
        }).Count -eq 1) `
            -Message 'TEST-0152 reserved protocol gitlink was dereferenced or lost.'
        Assert-True -Condition (@($reservedGraph.edges | Where-Object {
            $_.source -ceq 'AGENTS.md' -and
            $_.target -ceq '.ai/protocol/PROTOCOL.md' -and
            $_.reason -ceq 'MarkdownLink'
        }).Count -eq 1) `
            -Message 'TEST-0152 reserved protocol edge lost its extraction reason or terminal node evidence.'
        Assert-True -Condition (@($reservedGraph.protocolSurfaces) -ccontains `
            '.ai/protocol') `
            -Message 'TEST-0152 reserved protocol seed regressed from surface projection.'

        $legacyProtocolFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' =
                'Required reading: [legacy protocol](.ai/protocol/PROTOCOL.md).'
            '.ai/protocol/PROTOCOL.md' =
                'Required reading: [legacy state](LEGACY_STATE.md).'
            '.ai/protocol/LEGACY_STATE.md' = 'Legacy copied protocol state.'
        }) -SpecialEntries @{
            '.ai' = [pscustomobject]@{
                Mode = '040000'; Type = 'tree'; Sha = ('1' * 40)
            }
            '.ai/protocol' = [pscustomobject]@{
                Mode = '040000'; Type = 'tree'; Sha = ('2' * 40)
            }
        }
        $legacyProtocolGraph = & $graphBuilder -BaseHead ('f' * 40) `
            -TreeEntries $legacyProtocolFixture.Entries `
            -ReadBlob $legacyProtocolFixture.Reader
        Assert-True -Condition (
            @($legacyProtocolGraph.nodes | Where-Object {
                $_.path -ceq '.ai/protocol/PROTOCOL.md' -and
                $_.mode -ceq '100644' -and $_.type -ceq 'blob' -and
                $_.role -ceq 'ReferencedText'
            }).Count -eq 1 -and
            @($legacyProtocolGraph.edges | Where-Object {
                $_.source -ceq '.ai/protocol/PROTOCOL.md' -and
                $_.target -ceq '.ai/protocol/LEGACY_STATE.md' -and
                $_.kind -ceq 'RequiresRead'
            }).Count -eq 1
        ) -Message 'TEST-0152 a regular legacy .ai/protocol tree was mistaken for a canonical gitlink or omitted from migration evidence.'

        $realGitRoot = Join-Path ([IO.Path]::GetTempPath()) (
            'meandai-real-graph-' + [Guid]::NewGuid().ToString('N')
        )
        $hostedAcquisitionModule = $null
        [void][IO.Directory]::CreateDirectory($realGitRoot)
        try {
            [void](Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                -Arguments @('init', '-q'))
            [void](Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                -Arguments @('config', 'user.name', 'meAndAI graph fixture'))
            [void](Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                -Arguments @('config', 'user.email', 'graph-fixture@example.invalid'))
            [void](Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                -Arguments @('config', 'core.autocrlf', 'false'))
            [void](Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                -Arguments @('config', 'commit.gpgsign', 'false'))

            $fixtureUtf8 = [Text.UTF8Encoding]::new($false)
            $committedAgentsText = @(
                '# Exact committed instructions',
                '',
                'Required reading: [authority](docs/AUTHORITY.md).',
                'Required reading: [protocol](.ai/protocol/PROTOCOL.md).',
                'Additional evidence: [linked pointer](docs/governance/LINK.md).',
                ''
            ) -join "`n"
            $committedAuthorityText = @(
                '# Exact authority',
                '',
                'Committed authority remains live.',
                ''
            ) -join "`n"
            Set-TestFixtureBytes -Path (Join-Path $realGitRoot '.gitattributes') `
                -Bytes $fixtureUtf8.GetBytes("*.md text eol=crlf`n")
            Set-TestFixtureBytes -Path (Join-Path $realGitRoot 'AGENTS.md') `
                -Bytes $fixtureUtf8.GetBytes(
                    $committedAgentsText.Replace("`n", "`r`n")
                )
            Set-TestFixtureBytes `
                -Path (Join-Path $realGitRoot 'docs/AUTHORITY.md') `
                -Bytes $fixtureUtf8.GetBytes(
                    $committedAuthorityText.Replace("`n", "`r`n")
                )
            [void](Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                -Arguments @(
                    'add', '--', '.gitattributes', 'AGENTS.md',
                    'docs/AUTHORITY.md'
                ))
            [void](Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                -Arguments @('commit', '-q', '-m', 'Add exact graph roots'))
            $gitlinkTarget = [string]@(
                Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                    -Arguments @('rev-parse', 'HEAD')
            )[0].Trim()

            $linkPayloadPath = Join-Path $realGitRoot '.link-payload'
            Set-TestFixtureBytes -Path $linkPayloadPath `
                -Bytes $fixtureUtf8.GetBytes('../AUTHORITY.md')
            $linkBlob = [string]@(
                Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                    -Arguments @('hash-object', '-w', '--', $linkPayloadPath)
            )[0].Trim()
            Remove-Item -LiteralPath $linkPayloadPath -Force
            [void](Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                -Arguments @(
                    'update-index', '--add', '--cacheinfo',
                    "120000,$linkBlob,docs/governance/LINK.md"
                ))
            [void](Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                -Arguments @(
                    'update-index', '--add', '--cacheinfo',
                    "160000,$gitlinkTarget,.ai/protocol"
                ))
            [void](Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                -Arguments @('commit', '-q', '-m', 'Add exact special entries'))
            $realGitHead = [string]@(
                Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                    -Arguments @('rev-parse', 'HEAD')
            )[0].Trim()

            $worktreeAgentsText = @(
                '# CRLF worktree drift',
                '',
                'Required reading: [worktree only](docs/WORKTREE_ONLY.md).',
                ''
            ) -join "`r`n"
            Set-TestFixtureBytes -Path (Join-Path $realGitRoot 'AGENTS.md') `
                -Bytes $fixtureUtf8.GetBytes($worktreeAgentsText)
            Set-TestFixtureBytes `
                -Path (Join-Path $realGitRoot 'docs/AUTHORITY.md') `
                -Bytes $fixtureUtf8.GetBytes(
                    "# Changed worktree authority`r`n`r`nNot committed.`r`n"
                )

            $attributeEvidence = @(
                Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                    -Arguments @('check-attr', 'text', 'eol', '--', 'AGENTS.md')
            ) -join "`n"
            Assert-True -Condition (
                $attributeEvidence -like '*AGENTS.md: text: set*' -and
                $attributeEvidence -like '*AGENTS.md: eol: crlf*'
            ) -Message 'TEST-0152 real-Git fixture did not activate its committed text/EOL filter.'
            $worktreeAgentsBytes = [IO.File]::ReadAllBytes(
                (Join-Path $realGitRoot 'AGENTS.md')
            )
            Assert-True -Condition (
                $fixtureUtf8.GetString($worktreeAgentsBytes).Contains("`r`n")
            ) -Message 'TEST-0152 real-Git fixture did not retain CRLF worktree drift.'

            $quickEntries = @(Get-QuickAdoptionInstructionGraphTreeEntries `
                -Repository $realGitRoot -Commit $realGitHead)
            $quickGraph = Get-QuickAdoptionInstructionGraph `
                -Repository $realGitRoot -Commit $realGitHead
            $hostedAcquisitionModule = New-TestHostedGraphAcquisitionModule `
                -AdapterPath $hostedAdapterPath -PolicyModulePath $modulePath
            $hostedEntries = @(& $hostedAcquisitionModule {
                param($repository, $commit)
                @(Get-InstructionGraphTreeEntries -Repository $repository `
                    -Commit $commit)
            } $realGitRoot $realGitHead)
            $hostedGraph = & $hostedAcquisitionModule {
                param($repository, $commit)
                Get-InstructionGraphForCommit -Repository $repository `
                    -Commit $commit
            } $realGitRoot $realGitHead

            $quickEntryIdentity = @($quickEntries | ForEach-Object {
                "$([string]$_.Mode)`0$([string]$_.Type)`0" +
                    "$([string]$_.Sha)`0$([string]$_.Path)"
            })
            $hostedEntryIdentity = @($hostedEntries | ForEach-Object {
                "$([string]$_.Mode)`0$([string]$_.Type)`0" +
                    "$([string]$_.Sha)`0$([string]$_.Path)"
            })
            Assert-SequenceEqual -Actual $quickEntryIdentity `
                -Expected $hostedEntryIdentity `
                -Message 'TEST-0152 quick and hosted real ls-tree parsers diverged.'
            Assert-True -Condition (
                @($quickEntries | Where-Object {
                    $_.Path -ceq 'docs/governance/LINK.md' -and
                    $_.Mode -ceq '120000' -and $_.Type -ceq 'blob'
                }).Count -eq 1 -and
                @($quickEntries | Where-Object {
                    $_.Path -ceq '.ai/protocol' -and
                    $_.Mode -ceq '160000' -and $_.Type -ceq 'commit'
                }).Count -eq 1
            ) -Message 'TEST-0152 real ls-tree parsing lost mode 120000 or gitlink identity.'

            $quickAgentsEntry = @($quickEntries | Where-Object {
                $_.Path -ceq 'AGENTS.md'
            })[0]
            [byte[]]$quickAgentsBlob =
                Get-QuickAdoptionInstructionGraphBlobBytes `
                    -Repository $realGitRoot -Entry $quickAgentsEntry `
                    -MaximumBytes 262144
            [byte[]]$hostedAgentsBlob = & $hostedAcquisitionModule {
                param($repository, $entry)
                Get-InstructionGraphBlobBytes -Repository $repository `
                    -Entry $entry -MaximumBytes 262144
            } $realGitRoot $quickAgentsEntry
            $expectedAgentsBlob = $fixtureUtf8.GetBytes($committedAgentsText)
            Assert-True -Condition (
                (Get-TestSha256Hex -Bytes $quickAgentsBlob) -ceq
                    (Get-TestSha256Hex -Bytes $expectedAgentsBlob) -and
                (Get-TestSha256Hex -Bytes $hostedAgentsBlob) -ceq
                    (Get-TestSha256Hex -Bytes $expectedAgentsBlob) -and
                (Get-TestSha256Hex -Bytes $worktreeAgentsBytes) -cne
                    (Get-TestSha256Hex -Bytes $expectedAgentsBlob)
            ) -Message 'TEST-0152 cat-file acquisition used CRLF/filter-affected worktree bytes instead of the exact LF blob.'
            Assert-True -Condition (
                [string]$quickGraph.digest -ceq [string]$hostedGraph.digest -and
                [string]$quickGraph.baseHead -ceq $realGitHead -and
                @($quickGraph.nodes.path) -ccontains 'docs/AUTHORITY.md' -and
                @($quickGraph.nodes.path) -cnotcontains 'docs/WORKTREE_ONLY.md' -and
                @($quickGraph.nodes | Where-Object {
                    $_.path -ceq 'docs/governance/LINK.md' -and
                    $_.mode -ceq '120000' -and
                    $_.role -ceq 'ProtectedNonText'
                }).Count -eq 1 -and
                @($quickGraph.nodes | Where-Object {
                    $_.path -ceq '.ai/protocol' -and
                    $_.mode -ceq '160000' -and $_.type -ceq 'commit'
                }).Count -eq 1
            ) -Message 'TEST-0152 production adapters diverged or dereferenced worktree/special-entry evidence.'
        }
        catch {
            Add-Failure (
                'TEST-0152 real-Git exact acquisition fixture failed: ' +
                $_.Exception.Message
            )
        }
        finally {
            if (Test-Path -LiteralPath $realGitRoot) {
                $fixtureParent = [IO.DirectoryInfo]::new($realGitRoot).Parent.FullName
                $expectedParent = [IO.DirectoryInfo]::new(
                    [IO.Path]::GetTempPath()
                ).FullName
                $trimSeparators = [char[]]@(
                    [IO.Path]::DirectorySeparatorChar,
                    [IO.Path]::AltDirectorySeparatorChar
                )
                $fixtureParent = $fixtureParent.TrimEnd($trimSeparators)
                $expectedParent = $expectedParent.TrimEnd($trimSeparators)
                if (-not $fixtureParent.Equals(
                    $expectedParent, [StringComparison]::OrdinalIgnoreCase
                )) {
                    Add-Failure 'TEST-0152 refused to clean a fixture outside the exact temporary root.'
                }
                else {
                    try {
                        Remove-Item -LiteralPath $realGitRoot -Recurse -Force
                    }
                    catch {
                        Add-Failure (
                            'TEST-0152 could not clean its isolated Git fixture: ' +
                            $_.Exception.Message
                        )
                    }
                }
            }
        }

        $limits = & $limitGetter
        Assert-True -Condition (
            [int]$limits.MaximumTreeEntries -eq 65536 -and
            [int]$limits.MaximumTreePathUtf8Bytes -eq 4194304 -and
            [int]$limits.MaximumNodes -eq 256 -and
            [int]$limits.MaximumEdges -eq 2048 -and
            [int]$limits.MaximumDepth -eq 32 -and
            [int]$limits.MaximumBlobBytes -eq 262144 -and
            [int]$limits.MaximumAggregateBlobBytes -eq 4194304 -and
            [int]$limits.MaximumPathUtf8Bytes -eq 16384
        ) -Message 'TEST-0152 release-owned graph limits differ from DEC-0024.'

        $invalidUtf8Fixture = New-TestByteGraphFixture -Files ([ordered]@{
            'AGENTS.md' = [byte[]]@(0xC3, 0x28)
        })
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('1' * 40) `
                -TreeEntries $invalidUtf8Fixture.Entries `
                -ReadBlob $invalidUtf8Fixture.Reader
        } -Pattern '*not valid UTF-8*' `
            -Message 'TEST-0152 invalid UTF-8 instruction evidence did not fail closed.'

        $aliasBytes = [Text.UTF8Encoding]::new($false).GetBytes('instructions')
        $aliasSha = Get-TestGitBlobSha -Bytes $aliasBytes
        $caseAliasEntries = @(
            (New-TestTreeEntry -Path 'AGENTS.md' -Sha $aliasSha),
            (New-TestTreeEntry -Path 'agents.md' -Sha $aliasSha)
        )
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('2' * 40) `
                -TreeEntries $caseAliasEntries -ReadBlob { return ,$aliasBytes }
        } -Pattern '*case-ambiguous*' `
            -Message 'TEST-0152 case-insensitive path aliases did not fail closed.'

        $nfcPath = 'docs/features/caf' + [char]0x00E9 + '.md'
        $nfdPath = 'docs/features/cafe' + [char]0x0301 + '.md'
        $unicodeAliasEntries = @(
            (New-TestTreeEntry -Path $nfcPath),
            (New-TestTreeEntry -Path $nfdPath)
        )
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('3' * 40) `
                -TreeEntries $unicodeAliasEntries -ReadBlob {
                    throw 'Unicode alias validation read an untrusted blob.'
                }
        } -Pattern '*Unicode-ambiguous*' `
            -Message 'TEST-0152 NFC-equivalent path aliases did not fail closed.'

        $treeRootBytes = [Text.UTF8Encoding]::new($false).GetBytes('instructions')
        $treeRootSha = Get-TestGitBlobSha -Bytes $treeRootBytes
        $treeAtLimit = [object[]]::new([int]$limits.MaximumTreeEntries)
        $treeAtLimit[0] = New-TestTreeEntry -Path 'AGENTS.md' -Sha $treeRootSha
        for ($index = 1; $index -lt $treeAtLimit.Count; $index++) {
            $treeAtLimit[$index] = New-TestTreeEntry `
                -Path ('unknown/{0:D5}.bin' -f $index)
        }
        $treeReader = {
            param($entry)
            if ([string]$entry.Path -cne 'AGENTS.md') {
                throw "Unexpected blob read for '$([string]$entry.Path)'."
            }
            return ,$treeRootBytes
        }.GetNewClosure()
        $treeBoundaryGraph = & $graphBuilder -BaseHead ('4' * 40) `
            -TreeEntries $treeAtLimit -ReadBlob $treeReader
        Assert-True -Condition (@($treeBoundaryGraph.nodes).Count -eq 1) `
            -Message 'TEST-0152 exact tracked-tree boundary did not pass.'
        $treeOverLimit = [object[]]::new($treeAtLimit.Count + 1)
        [Array]::Copy($treeAtLimit, $treeOverLimit, $treeAtLimit.Count)
        $treeOverLimit[$treeAtLimit.Count] = New-TestTreeEntry `
            -Path 'unknown/overflow.bin'
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('4' * 40) `
                -TreeEntries $treeOverLimit -ReadBlob $treeReader
        } -Pattern '*tracked-tree budget*' `
            -Message 'TEST-0152 tracked-tree N+1 did not fail closed.'

        $treePathAtLimit = [System.Collections.Generic.List[object]]::new()
        [byte[]]$treePathRootBytes =
            [Text.UTF8Encoding]::new($false).GetBytes('Instructions.')
        $treePathAtLimit.Add((New-TestTreeEntry -Path 'AGENTS.md' `
            -Sha (Get-TestGitBlobSha -Bytes $treePathRootBytes)))
        [long]$remainingTreePathBytes =
            [long]$limits.MaximumTreePathUtf8Bytes -
            [Text.Encoding]::UTF8.GetByteCount('AGENTS.md')
        $index = 0
        while ($remainingTreePathBytes -gt 0) {
            $targetPathBytes = [int][Math]::Min(
                [long]$limits.MaximumPathUtf8Bytes,
                $remainingTreePathBytes
            )
            $prefix = 'unknown/{0:D3}/' -f $index
            $suffix = '.bin'
            $paddingLength = $targetPathBytes -
                [Text.Encoding]::UTF8.GetByteCount($prefix + $suffix)
            $path = $prefix + ('x' * $paddingLength) + $suffix
            if ([Text.Encoding]::UTF8.GetByteCount($path) -ne
                $targetPathBytes) {
                throw 'TEST-0152 tree-path fixture did not remain within the per-path limit.'
            }
            $treePathAtLimit.Add((New-TestTreeEntry -Path $path))
            $remainingTreePathBytes -= $targetPathBytes
            $index++
        }
        $treePathBudgetReader = {
            param($entry)
            if ([string]$entry.Path -cne 'AGENTS.md') {
                throw 'Unknown tree-path budget evidence was dereferenced.'
            }
            return ,$treePathRootBytes
        }.GetNewClosure()
        $treePathBoundaryGraph = & $graphBuilder -BaseHead ('4' * 40) `
            -TreeEntries @($treePathAtLimit) -ReadBlob $treePathBudgetReader
        $treePathBoundaryIdentity = & $graphIdentityGetter `
            -Graph $treePathBoundaryGraph
        Assert-True -Condition (
            [long]$treePathBoundaryGraph.counts.treePathUtf8Bytes -eq
                [long]$limits.MaximumTreePathUtf8Bytes -and
            [long]$treePathBoundaryIdentity.graphCounts.treePathUtf8Bytes -eq
                [long]$limits.MaximumTreePathUtf8Bytes -and
            [long]$treePathBoundaryIdentity.graphLimits.maximumTreePathUtf8Bytes -eq
                [long]$limits.MaximumTreePathUtf8Bytes -and
            [bool](& $graphIdentityRecordValidator `
                -Identity $treePathBoundaryIdentity)
        ) -Message 'TEST-0152 exact tracked-tree path-byte boundary was not preserved in graph count and identity.'
        $treePathOverLimit = @($treePathAtLimit) + @(
            (New-TestTreeEntry -Path 'z')
        )
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('4' * 40) `
                -TreeEntries $treePathOverLimit -ReadBlob {
                    throw 'Over-limit tree-path evidence was dereferenced.'
                }
        } -Pattern '*tracked-tree path budget*' `
            -Message 'TEST-0152 tracked-tree path-byte N+1 did not fail closed.'

        $nodeAtLimit = [object[]]::new([int]$limits.MaximumNodes)
        for ($index = 0; $index -lt $nodeAtLimit.Count; $index++) {
            $nodeAtLimit[$index] = New-TestTreeEntry `
                -Path ('docs/features/N{0:D3}.md' -f $index)
        }
        $nodeBoundaryGraph = & $graphBuilder -BaseHead ('5' * 40) `
            -TreeEntries $nodeAtLimit -ReadBlob {
                throw 'Unlinked node-boundary evidence was dereferenced.'
            }
        Assert-True -Condition (@($nodeBoundaryGraph.nodes).Count -eq
            [int]$limits.MaximumNodes) `
            -Message 'TEST-0152 exact node boundary did not pass.'
        $nodeOverLimit = @($nodeAtLimit) + @(
            New-TestTreeEntry -Path 'docs/features/N256.md'
        )
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('5' * 40) `
                -TreeEntries $nodeOverLimit -ReadBlob {
                    throw 'Over-limit node evidence was dereferenced.'
                }
        } -Pattern '*node budget*' `
            -Message 'TEST-0152 node N+1 did not fail closed.'

        $edgeLines = [System.Collections.Generic.List[string]]::new()
        for ($index = 0; $index -lt [int]$limits.MaximumEdges; $index++) {
            $edgeLines.Add(
                'Reference [edge{0}](https://example.com/evidence/{0}).' -f $index
            )
        }
        $edgeFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = @($edgeLines) -join "`n"
        })
        $edgeBoundaryGraph = & $graphBuilder -BaseHead ('6' * 40) `
            -TreeEntries $edgeFixture.Entries -ReadBlob $edgeFixture.Reader
        Assert-True -Condition (@($edgeBoundaryGraph.edges).Count -eq
            [int]$limits.MaximumEdges) `
            -Message 'TEST-0152 exact edge boundary did not pass.'
        $edgeLines.Add('Reference [overflow](https://example.com/overflow).')
        $edgeOverflowFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = @($edgeLines) -join "`n"
        })
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('6' * 40) `
                -TreeEntries $edgeOverflowFixture.Entries `
                -ReadBlob $edgeOverflowFixture.Reader
        } -Pattern '*edge budget*' `
            -Message 'TEST-0152 edge N+1 did not fail closed.'

        $depthFixture = New-TestDepthFixture `
            -Depth ([int]$limits.MaximumDepth)
        $depthBoundaryGraph = & $graphBuilder -BaseHead ('7' * 40) `
            -TreeEntries $depthFixture.Entries -ReadBlob $depthFixture.Reader
        Assert-True -Condition (@($depthBoundaryGraph.nodes).Count -eq
            ([int]$limits.MaximumDepth + 1)) `
            -Message 'TEST-0152 exact traversal-depth boundary did not pass.'
        $depthOverflowFixture = New-TestDepthFixture `
            -Depth ([int]$limits.MaximumDepth + 1)
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('7' * 40) `
                -TreeEntries $depthOverflowFixture.Entries `
                -ReadBlob $depthOverflowFixture.Reader
        } -Pattern '*traversal-depth budget*' `
            -Message 'TEST-0152 traversal-depth N+1 did not fail closed.'

        $protectedDepthBoundaryFixture =
            New-TestProtectedTerminalDepthFixture `
                -TextDepth ([int]$limits.MaximumDepth - 1)
        $protectedDepthBoundaryGraph = & $graphBuilder `
            -BaseHead ('7' * 40) `
            -TreeEntries $protectedDepthBoundaryFixture.Entries `
            -ReadBlob $protectedDepthBoundaryFixture.Reader
        Assert-True -Condition (
            @($protectedDepthBoundaryGraph.nodes | Where-Object {
                $_.path -ceq 'docs/depth/evidence.pdf' -and
                $_.role -ceq 'ProtectedNonText'
            }).Count -eq 1 -and
            [bool](& $graphValidator -Graph $protectedDepthBoundaryGraph)
        ) -Message 'TEST-0152 protected terminal at the exact depth boundary did not remain builder/validator exact.'
        $protectedReasonDriftGraph = Copy-TestInstructionGraph `
            -Graph $protectedDepthBoundaryGraph
        $protectedReasonDriftNode = @(
            $protectedReasonDriftGraph.nodes | Where-Object {
                [string]$_.role -ceq 'ProtectedNonText'
            } | Select-Object -First 1
        )[0]
        $protectedReasonDriftNode.reasons = @('MadeUpReason')
        Set-TestInstructionGraphDigest -Graph $protectedReasonDriftGraph `
            -PolicyModule $policyModule
        Assert-True -Condition (-not (& $graphValidator `
            -Graph $protectedReasonDriftGraph)) `
            -Message 'TEST-0151 exact validator accepted fabricated protected-terminal discovery reasons.'
        $protectedAuthorityGraph = Copy-TestInstructionGraph `
            -Graph $protectedDepthBoundaryGraph
        $protectedAuthorityEdge = @(
            $protectedAuthorityGraph.edges | Where-Object {
                [string]$_.target -ceq 'docs/depth/evidence.pdf'
            } | Select-Object -First 1
        )[0]
        $protectedAuthorityEdge.kind = 'DeclaresAuthority'
        $protectedAuthorityGraph.edges = @(
            Sort-TestInstructionGraphEdges `
                -Edges @($protectedAuthorityGraph.edges)
        )
        $protectedAuthorityNode = @(
            $protectedAuthorityGraph.nodes | Where-Object {
                [string]$_.path -ceq 'docs/depth/evidence.pdf'
            } | Select-Object -First 1
        )[0]
        $protectedAuthorityNode.reasons = @('DeclaresAuthority')
        Set-TestInstructionGraphDigest -Graph $protectedAuthorityGraph `
            -PolicyModule $policyModule
        Assert-True -Condition (-not (& $graphValidator `
            -Graph $protectedAuthorityGraph)) `
            -Message 'TEST-0151 exact validator accepted protected evidence as significant live authority.'
        $protectedDepthOverflowFixture =
            New-TestProtectedTerminalDepthFixture `
                -TextDepth ([int]$limits.MaximumDepth)
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('7' * 40) `
                -TreeEntries $protectedDepthOverflowFixture.Entries `
                -ReadBlob $protectedDepthOverflowFixture.Reader
        } -Pattern '*traversal-depth budget*' `
            -Message 'TEST-0152 protected terminal beyond the traversal-depth boundary did not fail closed.'

        $depthBackEdgeFixture = New-TestDepthBackEdgeFixture `
            -Depth ([int]$limits.MaximumDepth)
        $depthBackEdgeGraph = & $graphBuilder -BaseHead ('7' * 40) `
            -TreeEntries $depthBackEdgeFixture.Entries `
            -ReadBlob $depthBackEdgeFixture.Reader
        Assert-True -Condition (
            [bool](& $graphValidator -Graph $depthBackEdgeGraph) -and
            @($depthBackEdgeGraph.edges | Where-Object {
                $_.source -ceq 'docs/depth/32.md' -and
                $_.target -ceq 'AGENTS.md'
            }).Count -eq 1
        ) -Message 'TEST-0152 exact-depth cycle/back-edge was treated as a new traversal level.'

        $blobAtLimit = [byte[]]::new([int]$limits.MaximumBlobBytes)
        for ($index = 0; $index -lt $blobAtLimit.Length; $index++) {
            $blobAtLimit[$index] = 0x20
        }
        $blobBoundaryFixture = New-TestByteGraphFixture -Files ([ordered]@{
            'AGENTS.md' = $blobAtLimit
        })
        $blobBoundaryGraph = & $graphBuilder -BaseHead ('8' * 40) `
            -TreeEntries $blobBoundaryFixture.Entries `
            -ReadBlob $blobBoundaryFixture.Reader
        Assert-True -Condition (@($blobBoundaryGraph.nodes).Count -eq 1) `
            -Message 'TEST-0152 exact per-blob boundary did not pass.'
        $blobOverLimit = [byte[]]::new($blobAtLimit.Length + 1)
        for ($index = 0; $index -lt $blobOverLimit.Length; $index++) {
            $blobOverLimit[$index] = 0x20
        }
        $blobOverflowFixture = New-TestByteGraphFixture -Files ([ordered]@{
            'AGENTS.md' = $blobOverLimit
        })
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('8' * 40) `
                -TreeEntries $blobOverflowFixture.Entries `
                -ReadBlob $blobOverflowFixture.Reader
        } -Pattern '*per-blob budget*' `
            -Message 'TEST-0152 per-blob N+1 did not fail closed.'

        $aggregateFiles = [ordered]@{}
        $aggregateBlobCount = [int](
            [int]$limits.MaximumAggregateBlobBytes / `
            [int]$limits.MaximumBlobBytes
        )
        for ($index = 0; $index -lt $aggregateBlobCount; $index++) {
            $bytes = [byte[]]::new([int]$limits.MaximumBlobBytes)
            for ($byteIndex = 0; $byteIndex -lt $bytes.Length; $byteIndex++) {
                $bytes[$byteIndex] = 0x20
            }
            $aggregateFiles['scope{0:D2}/AGENTS.md' -f $index] = $bytes
        }
        $aggregateFixture = New-TestByteGraphFixture -Files $aggregateFiles
        $aggregateBoundaryGraph = & $graphBuilder -BaseHead ('9' * 40) `
            -TreeEntries $aggregateFixture.Entries `
            -ReadBlob $aggregateFixture.Reader
        Assert-True -Condition (@($aggregateBoundaryGraph.nodes).Count -eq
            $aggregateBlobCount) `
            -Message 'TEST-0152 exact aggregate-blob boundary did not pass.'
        $aggregateOverflowFiles = [ordered]@{}
        foreach ($path in $aggregateFiles.Keys) {
            $aggregateOverflowFiles[$path] = $aggregateFiles[$path]
        }
        $aggregateOverflowFiles['zz-overflow/AGENTS.md'] = [byte[]]@(0x20)
        $aggregateOverflowFixture = New-TestByteGraphFixture `
            -Files $aggregateOverflowFiles
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('9' * 40) `
                -TreeEntries $aggregateOverflowFixture.Entries `
                -ReadBlob $aggregateOverflowFixture.Reader
        } -Pattern '*aggregate parsed-blob budget*' `
            -Message 'TEST-0152 aggregate-blob N+1 did not fail closed.'

        $firstPath = 'docs/features/a.md'
        $longPathPrefix = 'docs/features/'
        $longPathSuffix = '.md'
        $longNameBytes = [int]$limits.MaximumPathUtf8Bytes -
            [Text.Encoding]::UTF8.GetByteCount($firstPath) - 1 -
            [Text.Encoding]::UTF8.GetByteCount($longPathPrefix) -
            [Text.Encoding]::UTF8.GetByteCount($longPathSuffix)
        $longPath = $longPathPrefix + ('b' * $longNameBytes) + $longPathSuffix
        $pathBoundaryEntries = @(
            (New-TestTreeEntry -Path $firstPath),
            (New-TestTreeEntry -Path $longPath)
        )
        $pathBoundaryGraph = & $graphBuilder -BaseHead ('a' * 40) `
            -TreeEntries $pathBoundaryEntries -ReadBlob {
                throw 'Unlinked path-boundary evidence was dereferenced.'
            }
        Assert-True -Condition (
            [Text.Encoding]::UTF8.GetByteCount(
                (@($pathBoundaryGraph.nodes.path) -join "`n")
            ) -eq [int]$limits.MaximumPathUtf8Bytes
        ) -Message 'TEST-0152 exact path-inventory boundary did not pass.'
        $pathOverflowEntries = @(
            (New-TestTreeEntry -Path $firstPath),
            (New-TestTreeEntry -Path ($longPathPrefix +
                ('b' * ($longNameBytes + 1)) + $longPathSuffix))
        )
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('a' * 40) `
                -TreeEntries $pathOverflowEntries -ReadBlob {
                    throw 'Over-limit path evidence was dereferenced.'
                }
        } -Pattern '*path-inventory budget*' `
            -Message 'TEST-0152 path-inventory N+1 did not fail closed.'

        $head = [Text.Encoding]::ASCII.GetString(
            (Invoke-TestGitBytes -WorkingDirectory $root `
                -Arguments 'rev-parse HEAD')
        ).Trim()
        $selfFixture = Get-TestCommittedGraphFixture `
            -RepositoryRoot $root -BaseHead $head
        try {
            $selfGraph = & $graphBuilder -BaseHead $head `
                -TreeEntries $selfFixture.Entries -ReadBlob $selfFixture.Reader
            Assert-True -Condition ([bool](& $graphValidator -Graph $selfGraph)) `
                -Message 'TEST-0152 meAndAI HEAD did not satisfy its consumer graph contract.'
            Assert-True -Condition (
                [string]$selfGraph.baseHead -ceq $head -and
                @($selfGraph.nodes.path) -ccontains 'AGENTS.md' -and
                @($selfGraph.nodes.path) -ccontains 'PROTOCOL.md' -and
                @($selfGraph.nodes.path) -ccontains '.ai/memory/README.md' -and
                -not $graphBuilder.Parameters.ContainsKey('RepositoryName')
            ) -Message 'TEST-0152 self-consumer evidence used a repository-name bypass.'
        }
        catch {
            Add-Failure (
                'TEST-0152 meAndAI HEAD did not satisfy the same exact consumer ' +
                "graph contract: $($_.Exception.Message)"
            )
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Instruction-graph discovery tests failed with $($failures.Count) problem(s):" `
        -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Instruction-graph discovery tests passed.' -ForegroundColor Green
$scenarioResult = New-MeAndAIScenarioResult -Owner $owner `
    -SourcePaths @($PSCommandPath) -AuthorityPath $scenarioAuthorityPath
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + `
    ($scenarioResult | ConvertTo-Json -Compress))
