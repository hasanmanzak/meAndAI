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
Import-Module (Join-Path $root `
    'tests/infrastructure/MeAndAI.TestRuntime.psm1') -Force
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.TestContext.psm1') -Force
$contentIdentityModule = @(Import-Module `
    (Join-Path $root 'scripts/MeAndAI.ContentIdentity.psm1') -Force -PassThru)[0]
$getSha256Action = $contentIdentityModule.ExportedCommands[
    'Get-MeAndAISha256'
].ScriptBlock
$getGitBlobSha1Action = $contentIdentityModule.ExportedCommands[
    'Get-MeAndAIGitBlobSha1'
].ScriptBlock
$operationContract = Import-MeAndAITestOperationContract `
    -Path (Join-Path $root 'tests/fixture-operation-budgets.psd1')
$operationExpectation = Resolve-MeAndAITestOperationExpectation `
    -Contract $operationContract -Owner $owner -SuiteArguments @()
$script:InstructionGraphBlobProcessStarts = [long]0
$script:InstructionGraphBlobRequests = [long]0
$failureContext = New-MeAndAITestContext
Set-MeAndAITestContext -Context $failureContext
$failures = $failureContext.Failures

function Assert-True {
    param([bool]$Condition, [string]$Message)
    Assert-MeAndAITestCollectedTrue -Context $failureContext `
        -Condition $Condition -Message $Message
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
            -Sha (Get-MeAndAIGitBlobSha1 -Bytes $bytes)))
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
            Sha = Get-MeAndAIGitBlobSha1 -Bytes $bytes
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
        [Parameter(Mandatory)][string]$Arguments,
        [switch]$DisableReplaceObjects
    )

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'git'
    $startInfo.Arguments = $Arguments
    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    if ($DisableReplaceObjects) {
        [void]$startInfo.EnvironmentVariables
        $childEnvironment = $startInfo.EnvironmentVariables
        $childEnvironment['GIT_NO_REPLACE_OBJECTS'] = '1'
    }
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
    $state = [pscustomobject]@{
        Process = $null
        InputStream = $null
        OutputStream = $null
        ErrorTask = $null
        Started = $false
        Completed = $false
        Requests = [long]0
    }
    $ensureStarted = {
        if ($state.Started) { return }
        $startInfo = [Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = 'git'
        $startInfo.Arguments = 'cat-file --batch'
        $startInfo.WorkingDirectory = $RepositoryRoot
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardInput = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        [void]$startInfo.EnvironmentVariables
        $childEnvironment = $startInfo.EnvironmentVariables
        $childEnvironment['GIT_NO_REPLACE_OBJECTS'] = '1'
        $process = [Diagnostics.Process]::new()
        $process.StartInfo = $startInfo
        $state.Process = $process
        try {
            $originalInputEncoding = [Console]::InputEncoding
            try {
                # Windows PowerShell 5.1 has no StandardInputEncoding. Initialize
                # and capture the raw pipe while the enclosing writer is BOM-free.
                [Console]::InputEncoding = [Text.UTF8Encoding]::new($false)
                if (-not $process.Start()) {
                    throw 'Independent expected-graph batch reader did not start.'
                }
                $state.Started = $true
                $state.InputStream = $process.StandardInput.BaseStream
            }
            finally {
                [Console]::InputEncoding = $originalInputEncoding
            }
            $state.OutputStream = $process.StandardOutput.BaseStream
            $state.ErrorTask = $process.StandardError.ReadToEndAsync()
        }
        catch {
            if ($state.Started) {
                try {
                    if (-not $process.HasExited) { $process.Kill() }
                    [void]$process.WaitForExit(5000)
                }
                catch { }
            }
            $process.Dispose()
            $state.Process = $null
            $state.InputStream = $null
            $state.OutputStream = $null
            $state.ErrorTask = $null
            $state.Started = $false
            throw
        }
    }.GetNewClosure()
    $reader = {
        param($entry)

        if ($state.Completed -or [string]$entry.Type -cne 'blob' -or
            [string]$entry.Sha -cnotmatch '^[0-9a-f]{40}$') {
            throw 'Independent expected-graph batch reader received an invalid request.'
        }
        & $ensureStarted
        $request = [Text.Encoding]::ASCII.GetBytes(
            "$([string]$entry.Sha)`n"
        )
        $state.InputStream.Write($request, 0, $request.Length)
        $state.InputStream.Flush()
        $state.Requests++
        $header = [Collections.Generic.List[byte]]::new()
        while ($true) {
            $value = $state.OutputStream.ReadByte()
            if ($value -lt 0) {
                throw 'Independent expected-graph batch response ended before its header.'
            }
            if ($value -eq 10) { break }
            if ($value -gt 127 -or $header.Count -ge 128) {
                throw 'Independent expected-graph batch response header is invalid.'
            }
            $header.Add([byte]$value)
        }
        $match = [regex]::Match(
            [Text.Encoding]::ASCII.GetString($header.ToArray()),
            '^(?<oid>[0-9a-f]{40}) blob (?<size>0|[1-9][0-9]*)$'
        )
        [long]$size = 0
        if (-not $match.Success -or
            [string]$match.Groups['oid'].Value -cne [string]$entry.Sha -or
            -not [long]::TryParse(
                [string]$match.Groups['size'].Value,
                [Globalization.NumberStyles]::None,
                [Globalization.CultureInfo]::InvariantCulture,
                [ref]$size
            ) -or $size -gt [int]::MaxValue) {
            throw 'Independent expected-graph batch response identity is invalid.'
        }
        $payload = [byte[]]::new([int]$size)
        $offset = 0
        while ($offset -lt $payload.Length) {
            $read = $state.OutputStream.Read(
                $payload, $offset, $payload.Length - $offset
            )
            if ($read -le 0) {
                throw 'Independent expected-graph batch payload ended early.'
            }
            $offset += $read
        }
        if ($state.OutputStream.ReadByte() -ne 10 -or
            (Get-MeAndAIGitBlobSha1 -Bytes $payload) -cne [string]$entry.Sha) {
            throw 'Independent expected-graph batch payload identity differs.'
        }
        return ,$payload
    }.GetNewClosure()
    $complete = {
        if ($state.Completed) { return }
        $state.Completed = $true
        if (-not $state.Started) { return }
        try {
            $state.InputStream.Close()
            if ($state.OutputStream.ReadByte() -ne -1) {
                throw 'Independent expected-graph batch reader retained extra output.'
            }
            $state.Process.WaitForExit()
            $errorText = [string]$state.ErrorTask.Result
            if ($state.Process.ExitCode -ne 0) {
                throw "Independent expected-graph batch reader failed: $errorText"
            }
        }
        finally {
            if (-not $state.Process.HasExited) { $state.Process.Kill() }
            $state.Process.Dispose()
        }
    }.GetNewClosure()
    $abort = {
        if ($state.Completed) { return }
        $state.Completed = $true
        if ($state.Started) {
            if (-not $state.Process.HasExited) { $state.Process.Kill() }
            $state.Process.Dispose()
        }
    }.GetNewClosure()
    return [pscustomobject]@{
        Entries = @($entries)
        Reader = $reader
        Complete = $complete
        Abort = $abort
        State = $state
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
    $definitions = @($ast.FindAll({
        param($node)
        return $node -is [Management.Automation.Language.FunctionDefinitionAst]
    }, $true))
    $batchFactoryName = 'New-InstructionGraphBatchSession'
    $transportName = if (@($definitions | Where-Object {
        $_.Name -ceq $batchFactoryName
    }).Count -eq 1) {
        $batchFactoryName
    }
    else {
        # Preserve TEST-0152's real-Git evidence while TEST-0161 is
        # intentionally red for the absent production batch factory. Once the
        # factory exists, this isolated hosted module exercises only that shape.
        'Get-InstructionGraphBlobBytes'
    }
    $rootNames = @(
        'Get-InstructionGraphTreeEntries',
        $transportName,
        'Get-InstructionGraphForCommit'
    )
    $requiredNames = [Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    $pendingNames = [Collections.Generic.Queue[string]]::new()
    foreach ($name in $rootNames) { $pendingNames.Enqueue($name) }
    while ($pendingNames.Count -gt 0) {
        $name = $pendingNames.Dequeue()
        if (-not $requiredNames.Add($name)) { continue }
        $matches = @($definitions | Where-Object { $_.Name -ceq $name })
        if ($matches.Count -ne 1) {
            throw "Hosted adapter must define '$name' exactly once."
        }
        foreach ($call in @($matches[0].Body.FindAll({
            param($node)
            return $node -is [Management.Automation.Language.CommandAst]
        }, $true))) {
            $calledName = [string]$call.GetCommandName()
            if ([string]::IsNullOrEmpty($calledName)) { continue }
            if (@($definitions | Where-Object {
                $_.Name -ceq $calledName
            }).Count -eq 1 -and -not $requiredNames.Contains($calledName)) {
                $pendingNames.Enqueue($calledName)
            }
        }
        foreach ($reference in [regex]::Matches(
            [string]$matches[0].Extent.Text,
            '\$\{function:(?<name>[A-Za-z][A-Za-z0-9-]*)\}'
        )) {
            $referencedName = [string]$reference.Groups['name'].Value
            if (@($definitions | Where-Object {
                $_.Name -ceq $referencedName
            }).Count -eq 1 -and
                -not $requiredNames.Contains($referencedName)) {
                $pendingNames.Enqueue($referencedName)
            }
        }
    }
    $source = [System.Collections.Generic.List[string]]::new()
    foreach ($definition in $definitions) {
        if ($requiredNames.Contains([string]$definition.Name)) {
            $source.Add([string]$definition.Extent.Text)
        }
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

function New-TestStreamCaptureFaultFactoryModule {
    param(
        [Parameter(Mandatory)][string]$ActorPath,
        [Parameter(Mandatory)][string]$FactoryName
    )

    $tokens = $null
    $parseErrors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile(
        $ActorPath, [ref]$tokens, [ref]$parseErrors
    )
    if (@($parseErrors).Count -ne 0) {
        throw "Stream-capture fault actor could not be parsed: $($parseErrors[0].Message)"
    }
    $matches = @($ast.FindAll({
        param($node)
        return $node -is
            [Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -ceq $FactoryName
    }, $true))
    if ($matches.Count -ne 1) {
        throw "Stream-capture fault actor must define '$FactoryName' once."
    }
    $testFactoryName = 'New-TestStreamCaptureFaultSession'
    $renamePattern = [regex]::new(
        '(?m)^function\s+' + [regex]::Escape($FactoryName) + '\b'
    )
    $source = $renamePattern.Replace(
        [string]$matches[0].Extent.Text,
        "function $testFactoryName",
        1
    )
    $captureExpression = '$process.StandardOutput.BaseStream'
    if ([regex]::Matches(
        $source, [regex]::Escape($captureExpression)
    ).Count -ne 1) {
        throw 'Stream-capture fault injection point is missing or ambiguous.'
    }
    $source = $source.Replace(
        $captureExpression,
        "(& { throw 'synthetic stream-capture failure' })"
    )
    $module = New-Module -Name (
        'MeAndAI.TestStreamCaptureFault.' +
        [Guid]::NewGuid().ToString('N')
    ) -ScriptBlock ([scriptblock]::Create($source))
    return [pscustomobject]@{
        Module = $module
        FactoryName = $testFactoryName
    }
}

function Test-InstructionGraphBatchActorSourceContract {
    param(
        [Parameter(Mandatory)][string]$ActorLabel,
        [Parameter(Mandatory)][string]$ActorPath,
        [Parameter(Mandatory)][string]$FactoryName,
        [Parameter(Mandatory)][string]$GraphEntryName,
        [Parameter(Mandatory)][string]$LegacyBlobReaderName
    )

    $tokens = $null
    $parseErrors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile(
        $ActorPath, [ref]$tokens, [ref]$parseErrors
    )
    if (@($parseErrors).Count -ne 0) {
        Add-Failure (
            "TEST-0161 $ActorLabel actor does not parse for batch-contract " +
            "inspection: $($parseErrors[0].Message)"
        )
        return $false
    }

    $definitions = @($ast.FindAll({
        param($node)
        return $node -is [Management.Automation.Language.FunctionDefinitionAst]
    }, $true))
    $factoryDefinitions = @($definitions | Where-Object {
        $_.Name -ceq $FactoryName
    })
    $actorPasses = $true
    if ($factoryDefinitions.Count -ne 1) {
        Add-Failure (
            "TEST-0161 $ActorLabel actor must define private batch factory " +
            "'$FactoryName' exactly once; found $($factoryDefinitions.Count)."
        )
        $actorPasses = $false
    }
    else {
        $factory = $factoryDefinitions[0]
        $factoryParameters = if ($null -eq $factory.Body.ParamBlock) {
            @()
        }
        else {
            @($factory.Body.ParamBlock.Parameters)
        }
        $factoryParameterNames = @(
            $factoryParameters | ForEach-Object {
                [string]$_.Name.VariablePath.UserPath
            }
        )
        $hookOwners = @($definitions | Where-Object {
            if ($null -eq $_.Body.ParamBlock) { return $false }
            $parameterNames = @(
                $_.Body.ParamBlock.Parameters | ForEach-Object {
                    [string]$_.Name.VariablePath.UserPath
                }
            )
            $parameterNames -ccontains 'InternalTestHooks'
        })
        $internalHooksParameter = @(
            $factoryParameters | Where-Object {
                [string]$_.Name.VariablePath.UserPath -ceq 'InternalTestHooks'
            }
        )
        if ($factoryParameterNames -cnotcontains 'InternalTestHooks' -or
            $internalHooksParameter.Count -ne 1 -or
            $hookOwners.Count -ne 1 -or
            $hookOwners[0].Name -cne $FactoryName -or
            $internalHooksParameter[0].Extent.Text -match '(?i)Mandatory') {
            Add-Failure (
                "TEST-0161 $ActorLabel actor must expose one optional " +
                "InternalTestHooks parameter only on '$FactoryName'."
            )
            $actorPasses = $false
        }

        $factorySource = [string]$factory.Extent.Text
        if ($factorySource -cnotmatch '(?<![A-Za-z0-9_])TransportFactory(?![A-Za-z0-9_])' -or
            $factorySource -cnotmatch '(?<![A-Za-z0-9_])GetMonotonicMilliseconds(?![A-Za-z0-9_])') {
            Add-Failure (
                "TEST-0161 $ActorLabel batch test seam must name exactly the " +
                'transport-factory and monotonic-clock intents.'
            )
            $actorPasses = $false
        }
        if ($factorySource -cnotmatch (
            '(?i)(?<![A-Za-z0-9-])cat-file\s+--batch' +
            '(?![A-Za-z0-9-])'
        )) {
            Add-Failure (
                "TEST-0161 $ActorLabel batch factory must own one Git " +
                'cat-file --batch transport.'
            )
            $actorPasses = $false
        }
        if ($factorySource -cnotmatch (
            '(?s)EnvironmentVariables\s*\[\s*[''\"]' +
            'GIT_NO_REPLACE_OBJECTS[''\"]\s*\]\s*=\s*[''\"]1[''\"]'
        )) {
            Add-Failure (
                "TEST-0161 $ActorLabel batch factory does not disable Git " +
                'replace objects on its child process.'
            )
            $actorPasses = $false
        }
        if ($factorySource -cnotmatch (
            '(?s)UTF8Encoding\]\s*::\s*new\s*\(\s*\$false\s*\).*?' +
            'StandardInput\.BaseStream'
        ) -or $factorySource -cnotmatch (
            '(?s)CloseInput\s*=\s*\{.*?streamState\.Input\.Close\s*\('
        ) -or $factorySource -cmatch 'StandardInput\.Close\s*\(') {
            Add-Failure (
                "TEST-0161 $ActorLabel batch factory must capture a no-BOM " +
                'raw stdin pipe and close it without a text-writer preamble.'
            )
            $actorPasses = $false
        }
        if ($factorySource -cnotmatch (
            '(?s)catch\s*\{.*?\$started.*?\$process\.Kill\s*\(\s*\)' +
            '.*?WaitForExit\s*\(.*?AbortTimeoutMilliseconds.*?' +
            '\$process\.Dispose\s*\(\s*\)'
        )) {
            Add-Failure (
                "TEST-0161 $ActorLabel batch factory does not kill, reap, " +
                'and dispose a child after stream-capture failure.'
            )
            $actorPasses = $false
        }
    }

    $legacyDefinitions = @($definitions | Where-Object {
        $_.Name -ceq $LegacyBlobReaderName
    })
    $actorSource = [IO.File]::ReadAllText($ActorPath)
    if ($legacyDefinitions.Count -ne 0 -or
        $actorSource -match (
            '(?i)(?<![A-Za-z0-9-])cat-file\s+blob(?![A-Za-z0-9-])'
        )) {
        Add-Failure (
            "TEST-0161 $ActorLabel actor retains the per-blob reader or " +
            'literal Git cat-file blob process path.'
        )
        $actorPasses = $false
    }

    $graphEntries = @($definitions | Where-Object {
        $_.Name -ceq $GraphEntryName
    })
    if ($graphEntries.Count -ne 1) {
        Add-Failure (
            "TEST-0161 $ActorLabel graph entry '$GraphEntryName' is missing " +
            'or ambiguous.'
        )
        $actorPasses = $false
    }
    else {
        $factoryCalls = @($graphEntries[0].Body.FindAll({
            param($node)
            return $node -is [Management.Automation.Language.CommandAst] -and
                $node.GetCommandName() -ceq $FactoryName
        }, $true))
        $literalLimitsAreExact = $false
        if ($factoryCalls.Count -eq 1) {
            $constantValues = @($factoryCalls[0].FindAll({
                param($node)
                return $node -is [Management.Automation.Language.ConstantExpressionAst]
            }, $true) | ForEach-Object { $_.Value })
            $literalLimitsAreExact = $true
            foreach ($expectedLimit in @(120000, 5000, 128, 65536)) {
                $matchingLimits = @($constantValues | Where-Object {
                    $_ -is [ValueType] -and
                    [long]$_ -eq [long]$expectedLimit
                })
                if ($matchingLimits.Count -ne 1) {
                    $literalLimitsAreExact = $false
                }
            }
        }
        if ($factoryCalls.Count -ne 1 -or
            -not $literalLimitsAreExact -or
            $factoryCalls[0].Extent.Text -match '(?i)-InternalTestHooks\b') {
            Add-Failure (
                "TEST-0161 $ActorLabel graph entry must create one batch " +
                'session with literal 120000/5000/128/65536 production limits ' +
                'and no test hooks.'
            )
            $actorPasses = $false
        }
        $graphSource = [string]$graphEntries[0].Extent.Text
        $tryFinallyBlocks = @($graphEntries[0].Body.FindAll({
            param($node)
            return $node -is [Management.Automation.Language.TryStatementAst] `
                -and $null -ne $node.Finally
        }, $true))
        if ($tryFinallyBlocks.Count -ne 1 -or
            $graphSource -cnotmatch '(?i)\.Complete\b' -or
            $graphSource -cnotmatch '(?i)\.Abort\b') {
            Add-Failure (
                "TEST-0161 $ActorLabel graph entry must complete its batch " +
                'session and abort it from one finally boundary so builder ' +
                'or validator faults cannot leak the child.'
            )
            $actorPasses = $false
        }
    }

    return $actorPasses
}

function Get-TestOptionValue {
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Options,
        [Parameter(Mandatory)][string]$Name,
        $Default
    )

    if ($Options.Contains($Name)) { return $Options[$Name] }
    return $Default
}

function New-TestVirtualClock {
    param([long[]]$Values = @([long]0))

    $queue = [Collections.Generic.Queue[long]]::new()
    foreach ($value in @($Values)) { $queue.Enqueue([long]$value) }
    $state = [pscustomobject]@{
        Value = if ($queue.Count -gt 0) { [long]$queue.Peek() } else { [long]0 }
        Calls = [long]0
        Queue = $queue
    }
    $callback = {
        $state.Calls++
        if ($state.Queue.Count -gt 0) {
            $state.Value = [long]$state.Queue.Dequeue()
        }
        return [long]$state.Value
    }.GetNewClosure()
    return [pscustomobject]@{
        State = $state
        Callback = $callback
    }
}

function New-TestCompletedTask {
    param([bool]$Value = $true)

    $source = [Threading.Tasks.TaskCompletionSource[bool]]::new()
    $source.SetResult($Value)
    return $source.Task
}

function New-TestCompletedIntTask {
    param([int]$Value)

    $source = [Threading.Tasks.TaskCompletionSource[int]]::new()
    $source.SetResult($Value)
    return $source.Task
}

function New-TestFaultedTask {
    param([Parameter(Mandatory)][string]$Message, [switch]$Integer)

    if ($Integer) {
        $source = [Threading.Tasks.TaskCompletionSource[int]]::new()
        $source.SetException([IO.IOException]::new($Message))
        return $source.Task
    }
    $source = [Threading.Tasks.TaskCompletionSource[bool]]::new()
    $source.SetException([IO.IOException]::new($Message))
    return $source.Task
}

function Join-TestByteArrays {
    param([Parameter(Mandatory)][object[]]$Arrays)

    [long]$length = 0
    foreach ($array in @($Arrays)) { $length += ([byte[]]$array).Length }
    if ($length -gt [int]::MaxValue) { throw 'Test byte sequence is too large.' }
    $result = [byte[]]::new([int]$length)
    $offset = 0
    foreach ($array in @($Arrays)) {
        [byte[]]$bytes = [byte[]]$array
        [Array]::Copy($bytes, 0, $result, $offset, $bytes.Length)
        $offset += $bytes.Length
    }
    return ,$result
}

function New-TestBatchResponseBytes {
    param(
        [Parameter(Mandatory)][string]$Oid,
        [Parameter(Mandatory)][byte[]]$Payload,
        [string]$HeaderOid = $Oid,
        [string]$Type = 'blob',
        [string]$SizeText,
        [byte[]]$HeaderBytes,
        [switch]$OmitTrailer,
        [byte]$Trailer = 10,
        [byte[]]$Extra = @(),
        [int]$PayloadBytesToEmit = -1
    )

    if ($null -eq $HeaderBytes) {
        if ([string]::IsNullOrEmpty($SizeText)) {
            $SizeText = [string]$Payload.Length
        }
        $HeaderBytes = [Text.Encoding]::ASCII.GetBytes(
            "$HeaderOid $Type $SizeText`n"
        )
    }
    $emitLength = if ($PayloadBytesToEmit -lt 0) {
        $Payload.Length
    }
    else { [Math]::Min($PayloadBytesToEmit, $Payload.Length) }
    $emittedPayload = [byte[]]::new($emitLength)
    if ($emitLength -gt 0) {
        [Array]::Copy($Payload, 0, $emittedPayload, 0, $emitLength)
    }
    $parts = [Collections.Generic.List[object]]::new()
    $parts.Add([byte[]]$HeaderBytes)
    $parts.Add([byte[]]$emittedPayload)
    if (-not $OmitTrailer) { $parts.Add([byte[]]@($Trailer)) }
    if ($Extra.Length -gt 0) { $parts.Add([byte[]]$Extra) }
    return Join-TestByteArrays -Arrays @($parts)
}

function New-TestBatchTransport {
    param([System.Collections.IDictionary]$Options = @{})

    [byte[]]$output = [byte[]](Get-TestOptionValue -Options $Options `
        -Name Output -Default ([byte[]]@()))
    [byte[]]$standardError = [byte[]](Get-TestOptionValue -Options $Options `
        -Name StandardError -Default ([byte[]]@()))
    $waitQueue = [Collections.Generic.Queue[bool]]::new()
    foreach ($value in @((Get-TestOptionValue -Options $Options `
        -Name WaitForExitResults -Default @($true)))) {
        $waitQueue.Enqueue([bool]$value)
    }
    $state = [pscustomobject]@{
        StartCalls = [long]0
        WriteCalls = [long]0
        FlushCalls = [long]0
        OutputReadCalls = [long]0
        ErrorReadCalls = [long]0
        CloseInputCalls = [long]0
        WaitForExitCalls = [long]0
        WaitForExitMilliseconds = [Collections.Generic.List[int]]::new()
        KillCalls = [long]0
        DisposeCalls = [long]0
        Started = $false
        HasExited = $false
        Output = $output
        OutputOffset = [int]0
        StandardError = $standardError
        ErrorOffset = [int]0
        Input = [Collections.Generic.List[byte]]::new()
        PendingSources = [Collections.Generic.List[object]]::new()
        WaitQueue = $waitQueue
    }
    $startResult = [bool](Get-TestOptionValue -Options $Options `
        -Name StartResult -Default $true)
    $startThrows = [bool](Get-TestOptionValue -Options $Options `
        -Name StartThrows -Default $false)
    $writeFault = [bool](Get-TestOptionValue -Options $Options `
        -Name WriteFault -Default $false)
    $flushFault = [bool](Get-TestOptionValue -Options $Options `
        -Name FlushFault -Default $false)
    $outputFault = [bool](Get-TestOptionValue -Options $Options `
        -Name OutputFault -Default $false)
    $errorFault = [bool](Get-TestOptionValue -Options $Options `
        -Name ErrorFault -Default $false)
    $pendingOutput = [bool](Get-TestOptionValue -Options $Options `
        -Name PendingOutput -Default $false)
    $pendingError = [bool](Get-TestOptionValue -Options $Options `
        -Name PendingError -Default $false)
    $completePendingOnKill = [bool](Get-TestOptionValue -Options $Options `
        -Name CompletePendingOnKill -Default $true)
    $killExits = [bool](Get-TestOptionValue -Options $Options `
        -Name KillExits -Default $true)
    $killThrows = [bool](Get-TestOptionValue -Options $Options `
        -Name KillThrows -Default $false)
    $disposeThrows = [bool](Get-TestOptionValue -Options $Options `
        -Name DisposeThrows -Default $false)
    $exitCode = [int](Get-TestOptionValue -Options $Options `
        -Name ExitCode -Default 0)
    $outputChunkSize = [int](Get-TestOptionValue -Options $Options `
        -Name OutputChunkSize -Default 7)
    $errorChunkSize = [int](Get-TestOptionValue -Options $Options `
        -Name ErrorChunkSize -Default 11)
    $onWrite = Get-TestOptionValue -Options $Options -Name OnWrite -Default $null
    $onOutputRead = Get-TestOptionValue -Options $Options `
        -Name OnOutputRead -Default $null
    $onErrorRead = Get-TestOptionValue -Options $Options `
        -Name OnErrorRead -Default $null

    $transport = [pscustomobject][ordered]@{
        Start = {
            $state.StartCalls++
            if ($startThrows) { throw 'synthetic process-start failure' }
            if ($startResult) { $state.Started = $true }
            return $startResult
        }.GetNewClosure()
        WriteInputAsync = {
            param([byte[]]$bytes, [int]$offset = 0, [int]$count = -1)
            $state.WriteCalls++
            if ($count -lt 0) { $count = $bytes.Length - $offset }
            $writtenBytes = [byte[]]::new($count)
            if ($count -gt 0) {
                [Array]::Copy($bytes, $offset, $writtenBytes, 0, $count)
            }
            if ($null -ne $onWrite) { & $onWrite $state $writtenBytes }
            if ($writeFault) {
                return New-TestFaultedTask -Message 'synthetic broken stdin'
            }
            foreach ($value in $writtenBytes) {
                $state.Input.Add([byte]$value)
            }
            return New-TestCompletedTask
        }.GetNewClosure()
        FlushInputAsync = {
            $state.FlushCalls++
            if ($flushFault) {
                return New-TestFaultedTask -Message 'synthetic flush failure'
            }
            return New-TestCompletedTask
        }.GetNewClosure()
        ReadStandardOutputAsync = {
            param([byte[]]$buffer, [int]$offset, [int]$count)
            $state.OutputReadCalls++
            if ($null -ne $onOutputRead) { & $onOutputRead $state }
            if ($outputFault) {
                return New-TestFaultedTask `
                    -Message 'synthetic stdout failure' -Integer
            }
            if ($pendingOutput) {
                $source = [Threading.Tasks.TaskCompletionSource[int]]::new()
                $state.PendingSources.Add($source)
                return $source.Task
            }
            $remaining = $state.Output.Length - $state.OutputOffset
            if ($remaining -le 0) { return New-TestCompletedIntTask -Value 0 }
            $read = [Math]::Min($count, [Math]::Min(
                $remaining, $outputChunkSize
            ))
            [Array]::Copy(
                $state.Output, $state.OutputOffset, $buffer, $offset, $read
            )
            $state.OutputOffset += $read
            return New-TestCompletedIntTask -Value $read
        }.GetNewClosure()
        ReadStandardErrorAsync = {
            param([byte[]]$buffer, [int]$offset, [int]$count)
            $state.ErrorReadCalls++
            if ($null -ne $onErrorRead) { & $onErrorRead $state }
            if ($errorFault) {
                return New-TestFaultedTask `
                    -Message 'synthetic stderr failure' -Integer
            }
            if ($pendingError) {
                $source = [Threading.Tasks.TaskCompletionSource[int]]::new()
                $state.PendingSources.Add($source)
                return $source.Task
            }
            $remaining = $state.StandardError.Length - $state.ErrorOffset
            if ($remaining -le 0) { return New-TestCompletedIntTask -Value 0 }
            $read = [Math]::Min($count, [Math]::Min(
                $remaining, $errorChunkSize
            ))
            [Array]::Copy(
                $state.StandardError, $state.ErrorOffset, $buffer, $offset,
                $read
            )
            $state.ErrorOffset += $read
            return New-TestCompletedIntTask -Value $read
        }.GetNewClosure()
        CloseInput = {
            $state.CloseInputCalls++
        }.GetNewClosure()
        WaitForExit = {
            param([int]$milliseconds)
            $state.WaitForExitCalls++
            [void]$state.WaitForExitMilliseconds.Add($milliseconds)
            $result = if ($state.WaitQueue.Count -gt 0) {
                [bool]$state.WaitQueue.Dequeue()
            }
            else { $true }
            if ($result) { $state.HasExited = $true }
            return $result
        }.GetNewClosure()
        GetHasExited = {
            return [bool]$state.HasExited
        }.GetNewClosure()
        GetExitCode = {
            return [int]$exitCode
        }.GetNewClosure()
        Kill = {
            $state.KillCalls++
            if ($killThrows) { throw 'synthetic kill failure' }
            if ($completePendingOnKill) {
                foreach ($source in @($state.PendingSources)) {
                    if (-not $source.Task.IsCompleted) { $source.SetResult(0) }
                }
            }
            if ($killExits) { $state.HasExited = $true }
        }.GetNewClosure()
        Dispose = {
            $state.DisposeCalls++
            if ($disposeThrows) { throw 'synthetic dispose failure' }
        }.GetNewClosure()
    }
    return [pscustomobject]@{
        Transport = $transport
        State = $state
    }
}

function New-TestBatchHooks {
    param(
        [Parameter(Mandatory)]$TransportFixture,
        [Parameter(Mandatory)]$ClockFixture
    )

    $state = [pscustomobject]@{ FactoryCalls = [long]0 }
    $transportFactory = {
        param([string]$repository)
        $state.FactoryCalls++
        return $TransportFixture.Transport
    }.GetNewClosure()
    return [pscustomobject]@{
        Hooks = [pscustomobject][ordered]@{
            TransportFactory = $transportFactory
            GetMonotonicMilliseconds = $ClockFixture.Callback
        }
        State = $state
    }
}

function New-TestBatchGraphCounts {
    param([long]$ParsedBlobs, [long]$ParsedBlobBytes)

    return [pscustomobject]@{
        counts = [pscustomobject]@{
            parsedBlobs = [long]$ParsedBlobs
            parsedBlobBytes = [long]$ParsedBlobBytes
        }
    }
}

function Invoke-TestActorBatchFactory {
    param(
        [Parameter(Mandatory)][ValidateSet('quick', 'hosted')]
        [string]$Actor,
        [Parameter(Mandatory)]$HostedModule,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Arguments
    )

    if ($Actor -ceq 'quick') {
        return New-QuickAdoptionInstructionGraphBatchSession @Arguments
    }
    return & $HostedModule {
        param($factoryArguments)
        New-InstructionGraphBatchSession @factoryArguments
    } $Arguments
}

function New-TestActorBatchSessionFixture {
    param(
        [Parameter(Mandatory)][ValidateSet('quick', 'hosted')]
        [string]$Actor,
        [Parameter(Mandatory)]$HostedModule,
        [System.Collections.IDictionary]$TransportOptions = @{},
        [long[]]$ClockValues = @([long]0),
        [long]$MaximumBlobBytes = 262144,
        [long]$MaximumAggregateBlobBytes = 4194304,
        [int]$SessionTimeoutMilliseconds = 120000,
        [int]$AbortTimeoutMilliseconds = 5000,
        [int]$MaximumHeaderBytes = 128,
        [int]$MaximumStandardErrorBytes = 65536
    )

    $transport = New-TestBatchTransport -Options $TransportOptions
    $clock = New-TestVirtualClock -Values $ClockValues
    $transport.State | Add-Member -NotePropertyName ClockState `
        -NotePropertyValue $clock.State -Force
    $hooks = New-TestBatchHooks -TransportFixture $transport `
        -ClockFixture $clock
    $arguments = [ordered]@{
        Repository = 'C:/synthetic/instruction-graph.git'
        MaximumBlobBytes = [long]$MaximumBlobBytes
        MaximumAggregateBlobBytes = [long]$MaximumAggregateBlobBytes
        SessionTimeoutMilliseconds = [int]$SessionTimeoutMilliseconds
        AbortTimeoutMilliseconds = [int]$AbortTimeoutMilliseconds
        MaximumHeaderBytes = [int]$MaximumHeaderBytes
        MaximumStandardErrorBytes = [int]$MaximumStandardErrorBytes
        InternalTestHooks = $hooks.Hooks
    }
    $session = Invoke-TestActorBatchFactory -Actor $Actor `
        -HostedModule $HostedModule -Arguments $arguments
    return [pscustomobject]@{
        Session = $session
        Transport = $transport
        Clock = $clock
        Hooks = $hooks
    }
}

function Test-InstructionGraphBatchActorBehavior {
    param(
        [Parameter(Mandatory)][ValidateSet('quick', 'hosted')]
        [string]$Actor,
        [Parameter(Mandatory)]$HostedModule,
        [Parameter(Mandatory)]$GraphBuilder,
        [Parameter(Mandatory)]$GraphValidator
    )

    $label = "TEST-0161 $Actor batch transport"
    $baseFactoryArguments = [ordered]@{
        Repository = 'C:/synthetic/instruction-graph.git'
        MaximumBlobBytes = [long]262144
        MaximumAggregateBlobBytes = [long]4194304
        SessionTimeoutMilliseconds = [int]120000
        AbortTimeoutMilliseconds = [int]5000
        MaximumHeaderBytes = [int]128
        MaximumStandardErrorBytes = [int]65536
    }
    $validTransport = New-TestBatchTransport
    $validClock = New-TestVirtualClock
    $validHooks = New-TestBatchHooks -TransportFixture $validTransport `
        -ClockFixture $validClock
    foreach ($badHookCase in @(
        [pscustomobject]@{
            Name = 'missing clock'
            Hooks = [pscustomobject][ordered]@{
                TransportFactory = $validHooks.Hooks.TransportFactory
            }
        },
        [pscustomobject]@{
            Name = 'unknown hook'
            Hooks = [pscustomobject][ordered]@{
                TransportFactory = $validHooks.Hooks.TransportFactory
                GetMonotonicMilliseconds = $validHooks.Hooks.GetMonotonicMilliseconds
                Unknown = { 0 }
            }
        },
        [pscustomobject]@{
            Name = 'non-scriptblock hook'
            Hooks = [pscustomobject][ordered]@{
                TransportFactory = 'not-a-scriptblock'
                GetMonotonicMilliseconds = $validHooks.Hooks.GetMonotonicMilliseconds
            }
        }
    )) {
        $arguments = [ordered]@{}
        foreach ($key in $baseFactoryArguments.Keys) {
            $arguments[$key] = $baseFactoryArguments[$key]
        }
        $arguments.InternalTestHooks = $badHookCase.Hooks
        Assert-ThrowsLike -Action {
            [void](Invoke-TestActorBatchFactory -Actor $Actor `
                -HostedModule $HostedModule -Arguments $arguments)
        }.GetNewClosure() -Pattern '*' `
            -Message "$label accepted $([string]$badHookCase.Name)."
    }

    $zero = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule
    & $zero.Session.Complete (New-TestBatchGraphCounts `
        -ParsedBlobs 0 -ParsedBlobBytes 0)
    $zeroObservation = & $zero.Session.GetObservation
    Assert-True -Condition (
        [long]$zero.Hooks.State.FactoryCalls -eq 0 -and
        [long]$zero.Transport.State.StartCalls -eq 0 -and
        [long]$zeroObservation.ProcessStarts -eq 0 -and
        [long]$zeroObservation.Requests -eq 0 -and
        [string]$zeroObservation.Lifecycle -ceq 'Completed'
    ) -Message "$label zero-read completion was not lazy."
    Assert-ThrowsLike -Action {
        & $zero.Session.ReadBlob (New-TestTreeEntry -Path 'after.md')
    }.GetNewClosure() -Pattern '*' `
        -Message "$label completed session remained readable."

    [byte[]]$binaryPayload = @(
        0, 10, 255, 35, 32, 104, 101, 97, 100, 101, 114, 32, 108,
        105, 107, 101, 10, 128, 1
    )
    $binaryOid = & $getGitBlobSha1Action -Bytes $binaryPayload
    $binaryResponse = New-TestBatchResponseBytes -Oid $binaryOid `
        -Payload $binaryPayload
    $one = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule -TransportOptions @{
            Output = $binaryResponse
            OutputChunkSize = 3
        }
    $binaryEntry = New-TestTreeEntry -Path 'AGENTS.md' -Sha $binaryOid
    [byte[]]$binaryActual = & $one.Session.ReadBlob $binaryEntry
    & $one.Session.Complete (New-TestBatchGraphCounts `
        -ParsedBlobs 1 -ParsedBlobBytes $binaryPayload.Length)
    $oneObservation = & $one.Session.GetObservation
    [byte[]]$oneInput = @($one.Transport.State.Input)
    [byte[]]$expectedOneInput = [Text.Encoding]::ASCII.GetBytes(
        "$binaryOid`n"
    )
    Assert-True -Condition (
        (& $getSha256Action -Bytes $binaryActual) -ceq
            (& $getSha256Action -Bytes $binaryPayload) -and
        (& $getSha256Action -Bytes $oneInput) -ceq
            (& $getSha256Action -Bytes $expectedOneInput) -and
        $oneInput.Length -eq 41 -and $oneInput[40] -eq 10 -and
        [long]$one.Hooks.State.FactoryCalls -eq 1 -and
        [long]$oneObservation.ProcessStarts -eq 1 -and
        [long]$oneObservation.Requests -eq 1 -and
        [long]$oneObservation.ResponseBytes -eq $binaryPayload.Length -and
        [string]$oneObservation.Lifecycle -ceq 'Completed' -and
        [long]$one.Transport.State.DisposeCalls -eq 1
    ) -Message "$label one-read binary framing or lifecycle differs."

    [byte[]]$secondPayload = [Text.UTF8Encoding]::new($false).GetBytes(
        "Required reading: [root](../AGENTS.md).`n"
    )
    $secondOid = & $getGitBlobSha1Action -Bytes $secondPayload
    $manyOutput = Join-TestByteArrays -Arrays @(
        (New-TestBatchResponseBytes -Oid $binaryOid -Payload $binaryPayload),
        (New-TestBatchResponseBytes -Oid $secondOid -Payload $secondPayload)
    )
    $many = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule -TransportOptions @{ Output = $manyOutput }
    [void](& $many.Session.ReadBlob $binaryEntry)
    [void](& $many.Session.ReadBlob (New-TestTreeEntry `
        -Path 'docs/AUTHORITY.md' -Sha $secondOid))
    & $many.Session.Complete (New-TestBatchGraphCounts -ParsedBlobs 2 `
        -ParsedBlobBytes ($binaryPayload.Length + $secondPayload.Length))
    $manyObservation = & $many.Session.GetObservation
    $expectedManyInput = [Text.Encoding]::ASCII.GetBytes(
        "$binaryOid`n$secondOid`n"
    )
    [byte[]]$manyInput = @($many.Transport.State.Input)
    Assert-True -Condition (
        [long]$manyObservation.ProcessStarts -eq 1 -and
        [long]$manyObservation.Requests -eq 2 -and
        (& $getSha256Action -Bytes $manyInput) -ceq
            (& $getSha256Action -Bytes $expectedManyInput)
    ) -Message "$label many-read request sequence was not one serial session."

    $duplicateOutput = Join-TestByteArrays -Arrays @(
        $binaryResponse, $binaryResponse
    )
    $duplicate = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule -TransportOptions @{
            Output = $duplicateOutput
        }
    [void](& $duplicate.Session.ReadBlob $binaryEntry)
    [void](& $duplicate.Session.ReadBlob (New-TestTreeEntry `
        -Path 'docs/SAME-CONTENT.md' -Sha $binaryOid))
    & $duplicate.Session.Complete (New-TestBatchGraphCounts `
        -ParsedBlobs 2 -ParsedBlobBytes (2 * $binaryPayload.Length))
    $duplicateObservation = & $duplicate.Session.GetObservation
    Assert-True -Condition (
        [long]$duplicateObservation.ProcessStarts -eq 1 -and
        [long]$duplicateObservation.Requests -eq 2 -and
        $duplicate.Transport.State.Input.Count -eq 82
    ) -Message "$label duplicate OID was cached, prefetched, or reordered."

    [byte[]]$cycleRootBytes = [Text.UTF8Encoding]::new($false).GetBytes(
        'Required reading: [authority](docs/AUTHORITY.md).'
    )
    [byte[]]$cycleAuthorityBytes = [Text.UTF8Encoding]::new($false).GetBytes(
        'Reference: [root](../AGENTS.md).'
    )
    $cycleRootOid = & $getGitBlobSha1Action -Bytes $cycleRootBytes
    $cycleAuthorityOid = & $getGitBlobSha1Action -Bytes $cycleAuthorityBytes
    $cycle = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule -TransportOptions @{
            Output = (Join-TestByteArrays -Arrays @(
                (New-TestBatchResponseBytes -Oid $cycleRootOid `
                    -Payload $cycleRootBytes),
                (New-TestBatchResponseBytes -Oid $cycleAuthorityOid `
                    -Payload $cycleAuthorityBytes)
            ))
        }
    $cycleReader = {
        param($entry)
        & $cycle.Session.ReadBlob $entry
    }.GetNewClosure()
    $cycleGraph = & $GraphBuilder -BaseHead ('a' * 40) -TreeEntries @(
        (New-TestTreeEntry -Path 'AGENTS.md' -Sha $cycleRootOid),
        (New-TestTreeEntry -Path 'docs/AUTHORITY.md' -Sha $cycleAuthorityOid)
    ) -ReadBlob $cycleReader
    & $cycle.Session.Complete $cycleGraph
    Assert-True -Condition (
        [bool](& $GraphValidator -Graph $cycleGraph) -and
        [long]$cycleGraph.counts.parsedBlobs -eq 2 -and
        @($cycleGraph.edges | Where-Object {
            $_.source -ceq 'docs/AUTHORITY.md' -and
            $_.target -ceq 'AGENTS.md'
        }).Count -eq 1
    ) -Message "$label changed cyclic graph acquisition semantics."

    $malformedCases = @(
        [pscustomobject]@{
            Name = 'missing object header'
            Output = [Text.Encoding]::ASCII.GetBytes("$binaryOid missing`n")
        },
        [pscustomobject]@{
            Name = 'ambiguous header'
            Output = [Text.Encoding]::ASCII.GetBytes(
                "$binaryOid blob $($binaryPayload.Length) extra`n"
            )
        },
        [pscustomobject]@{
            Name = 'wrong oid'
            Output = New-TestBatchResponseBytes -Oid $binaryOid `
                -HeaderOid ('e' * 40) -Payload $binaryPayload
        },
        [pscustomobject]@{
            Name = 'wrong type'
            Output = New-TestBatchResponseBytes -Oid $binaryOid `
                -Type 'tree' -Payload $binaryPayload
        },
        [pscustomobject]@{
            Name = 'noncanonical size'
            Output = New-TestBatchResponseBytes -Oid $binaryOid `
                -SizeText ('0' + [string]$binaryPayload.Length) `
                -Payload $binaryPayload
        },
        [pscustomobject]@{
            Name = 'hash mismatch'
            Output = New-TestBatchResponseBytes -Oid $binaryOid `
                -Payload ([byte[]](1..$binaryPayload.Length))
        },
        [pscustomobject]@{
            Name = 'early eof'
            Output = New-TestBatchResponseBytes -Oid $binaryOid `
                -Payload $binaryPayload -PayloadBytesToEmit 3 -OmitTrailer
        },
        [pscustomobject]@{
            Name = 'missing trailer'
            Output = New-TestBatchResponseBytes -Oid $binaryOid `
                -Payload $binaryPayload -OmitTrailer
        },
        [pscustomobject]@{
            Name = 'bad trailer'
            Output = New-TestBatchResponseBytes -Oid $binaryOid `
                -Payload $binaryPayload -Trailer 13
        }
    )
    foreach ($case in $malformedCases) {
        $fault = New-TestActorBatchSessionFixture -Actor $Actor `
            -HostedModule $HostedModule -TransportOptions @{
                Output = [byte[]]$case.Output
            }
        Assert-ThrowsLike -Action {
            & $fault.Session.ReadBlob $binaryEntry
        }.GetNewClosure() -Pattern '*' `
            -Message "$label accepted $([string]$case.Name)."
        Assert-ThrowsLike -Action {
            & $fault.Session.ReadBlob $binaryEntry
        }.GetNewClosure() -Pattern '*' `
            -Message "$label $([string]$case.Name) was not terminal."
        try { & $fault.Session.Abort } catch { }
        $faultObservation = & $fault.Session.GetObservation
        Assert-True -Condition (
            [string]$faultObservation.Lifecycle -in @('Faulted', 'Aborted') -and
            [long]$fault.Transport.State.DisposeCalls -eq 1
        ) -Message "$label $([string]$case.Name) did not dispose exactly once."
    }

    foreach ($completionCase in @(
        [pscustomobject]@{
            Name = 'extra stdout'
            Options = @{
                Output = New-TestBatchResponseBytes -Oid $binaryOid `
                    -Payload $binaryPayload -Extra ([byte[]]@(88))
            }
        },
        [pscustomobject]@{
            Name = 'nonzero exit'
            Options = @{
                Output = $binaryResponse
                ExitCode = 17
            }
        }
    )) {
        $fault = New-TestActorBatchSessionFixture -Actor $Actor `
            -HostedModule $HostedModule -TransportOptions $completionCase.Options
        [void](& $fault.Session.ReadBlob $binaryEntry)
        Assert-ThrowsLike -Action {
            & $fault.Session.Complete (New-TestBatchGraphCounts `
                -ParsedBlobs 1 -ParsedBlobBytes $binaryPayload.Length)
        }.GetNewClosure() -Pattern '*' `
            -Message "$label accepted $([string]$completionCase.Name)."
        try { & $fault.Session.Abort } catch { }
    }

    $headerBytes = [Text.Encoding]::ASCII.GetBytes(
        "$binaryOid blob $($binaryPayload.Length)`n"
    )
    $headerAtN = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule `
        -MaximumHeaderBytes ($headerBytes.Length - 1) `
        -TransportOptions @{ Output = $binaryResponse }
    [void](& $headerAtN.Session.ReadBlob $binaryEntry)
    & $headerAtN.Session.Complete (New-TestBatchGraphCounts `
        -ParsedBlobs 1 -ParsedBlobBytes $binaryPayload.Length)
    $headerAtNPlusOne = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule `
        -MaximumHeaderBytes ($headerBytes.Length - 2) `
        -TransportOptions @{ Output = $binaryResponse }
    Assert-ThrowsLike -Action {
        & $headerAtNPlusOne.Session.ReadBlob $binaryEntry
    }.GetNewClosure() -Pattern '*' `
        -Message "$label header N+1 did not fail closed."
    try { & $headerAtNPlusOne.Session.Abort } catch { }

    [byte[]]$headerCeilingProbe = [byte[]]::new(256)
    for ($headerIndex = 0; $headerIndex -lt $headerCeilingProbe.Length;
        $headerIndex++) {
        $headerCeilingProbe[$headerIndex] = [byte]88
    }
    $headerAtExactProductionCeiling = New-TestActorBatchSessionFixture `
        -Actor $Actor -HostedModule $HostedModule -MaximumHeaderBytes 128 `
        -TransportOptions @{
            Output = $headerCeilingProbe
            OutputChunkSize = 1
        }
    Assert-ThrowsLike -Action {
        & $headerAtExactProductionCeiling.Session.ReadBlob $binaryEntry
    }.GetNewClosure() -Pattern '*' `
        -Message "$label exact 128-byte header ceiling was not enforced."
    Assert-True -Condition (
        [int]$headerAtExactProductionCeiling.Transport.State.OutputOffset -eq
            129
    ) -Message "$label header ceiling consumed beyond its N+1 sentinel."
    try { & $headerAtExactProductionCeiling.Session.Abort } catch { }

    $blobAtN = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule -MaximumBlobBytes $binaryPayload.Length `
        -TransportOptions @{ Output = $binaryResponse }
    [void](& $blobAtN.Session.ReadBlob $binaryEntry)
    & $blobAtN.Session.Complete (New-TestBatchGraphCounts `
        -ParsedBlobs 1 -ParsedBlobBytes $binaryPayload.Length)
    $blobAtNPlusOne = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule `
        -MaximumBlobBytes ($binaryPayload.Length - 1) `
        -TransportOptions @{ Output = $binaryResponse }
    Assert-ThrowsLike -Action {
        & $blobAtNPlusOne.Session.ReadBlob $binaryEntry
    }.GetNewClosure() -Pattern '*' `
        -Message "$label per-blob N+1 did not fail closed."
    try { & $blobAtNPlusOne.Session.Abort } catch { }

    $aggregateBytes = $binaryPayload.Length + $secondPayload.Length
    $aggregateAtN = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule -MaximumAggregateBlobBytes $aggregateBytes `
        -TransportOptions @{ Output = $manyOutput }
    [void](& $aggregateAtN.Session.ReadBlob $binaryEntry)
    [void](& $aggregateAtN.Session.ReadBlob (New-TestTreeEntry `
        -Path 'docs/AUTHORITY.md' -Sha $secondOid))
    & $aggregateAtN.Session.Complete (New-TestBatchGraphCounts `
        -ParsedBlobs 2 -ParsedBlobBytes $aggregateBytes)
    $aggregateAtNPlusOne = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule `
        -MaximumAggregateBlobBytes ($aggregateBytes - 1) `
        -TransportOptions @{ Output = $manyOutput }
    [void](& $aggregateAtNPlusOne.Session.ReadBlob $binaryEntry)
    Assert-ThrowsLike -Action {
        & $aggregateAtNPlusOne.Session.ReadBlob (New-TestTreeEntry `
            -Path 'docs/AUTHORITY.md' -Sha $secondOid)
    }.GetNewClosure() -Pattern '*' `
        -Message "$label aggregate N+1 did not fail closed."
    try { & $aggregateAtNPlusOne.Session.Abort } catch { }

    [byte[]]$productionBlobPayload = [byte[]]::new(262144)
    $productionBlobOid = & $getGitBlobSha1Action -Bytes $productionBlobPayload
    $productionBlobEntry = New-TestTreeEntry `
        -Path 'docs/PRODUCTION-LIMIT.md' -Sha $productionBlobOid
    [byte[]]$productionBlobResponse = New-TestBatchResponseBytes `
        -Oid $productionBlobOid -Payload $productionBlobPayload
    $productionBlobAtN = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule -MaximumBlobBytes 262144 `
        -TransportOptions @{
            Output = $productionBlobResponse
            OutputChunkSize = 65536
        }
    [void](& $productionBlobAtN.Session.ReadBlob $productionBlobEntry)
    & $productionBlobAtN.Session.Complete (New-TestBatchGraphCounts `
        -ParsedBlobs 1 -ParsedBlobBytes 262144)

    [byte[]]$productionBlobAtNPlusOnePayload = [byte[]]::new(262145)
    $productionBlobAtNPlusOneOid = & $getGitBlobSha1Action `
        -Bytes $productionBlobAtNPlusOnePayload
    $productionBlobAtNPlusOne = New-TestActorBatchSessionFixture `
        -Actor $Actor -HostedModule $HostedModule `
        -MaximumBlobBytes 262144 `
        -TransportOptions @{
            Output = New-TestBatchResponseBytes `
                -Oid $productionBlobAtNPlusOneOid `
                -Payload $productionBlobAtNPlusOnePayload `
                -PayloadBytesToEmit 0
            OutputChunkSize = 65536
        }
    Assert-ThrowsLike -Action {
        & $productionBlobAtNPlusOne.Session.ReadBlob (
            New-TestTreeEntry -Path 'docs/PRODUCTION-LIMIT-PLUS-ONE.md' `
                -Sha $productionBlobAtNPlusOneOid
        )
    }.GetNewClosure() -Pattern '*' `
        -Message "$label exact 262144-byte blob ceiling was not enforced."
    try { & $productionBlobAtNPlusOne.Session.Abort } catch { }

    $productionAggregateParts =
        [Collections.Generic.List[object]]::new()
    for ($aggregateIndex = 0; $aggregateIndex -lt 16;
        $aggregateIndex++) {
        $productionAggregateParts.Add($productionBlobResponse)
    }
    [byte[]]$productionAggregateResponse = Join-TestByteArrays `
        -Arrays @($productionAggregateParts)
    $productionAggregateAtN = New-TestActorBatchSessionFixture `
        -Actor $Actor -HostedModule $HostedModule `
        -MaximumAggregateBlobBytes 4194304 `
        -TransportOptions @{
            Output = $productionAggregateResponse
            OutputChunkSize = 65536
        }
    for ($aggregateIndex = 0; $aggregateIndex -lt 16;
        $aggregateIndex++) {
        [void](& $productionAggregateAtN.Session.ReadBlob (
            New-TestTreeEntry `
                -Path ('docs/aggregate/{0:D2}.md' -f $aggregateIndex) `
                -Sha $productionBlobOid
        ))
    }
    & $productionAggregateAtN.Session.Complete (New-TestBatchGraphCounts `
        -ParsedBlobs 16 -ParsedBlobBytes 4194304)

    [byte[]]$aggregateSentinelPayload = [byte[]]@(1)
    $aggregateSentinelOid = & $getGitBlobSha1Action `
        -Bytes $aggregateSentinelPayload
    [byte[]]$aggregateSentinelResponse = New-TestBatchResponseBytes `
        -Oid $aggregateSentinelOid -Payload $aggregateSentinelPayload `
        -PayloadBytesToEmit 0
    $productionAggregateNPlusOneParts =
        [Collections.Generic.List[object]]::new()
    $productionAggregateNPlusOneParts.Add($productionAggregateResponse)
    $productionAggregateNPlusOneParts.Add($aggregateSentinelResponse)
    [byte[]]$productionAggregateNPlusOneResponse = Join-TestByteArrays `
        -Arrays @($productionAggregateNPlusOneParts)
    $productionAggregateAtNPlusOne = New-TestActorBatchSessionFixture `
        -Actor $Actor -HostedModule $HostedModule `
        -MaximumAggregateBlobBytes 4194304 `
        -TransportOptions @{
            Output = $productionAggregateNPlusOneResponse
            OutputChunkSize = 65536
        }
    for ($aggregateIndex = 0; $aggregateIndex -lt 16;
        $aggregateIndex++) {
        [void](& $productionAggregateAtNPlusOne.Session.ReadBlob (
            New-TestTreeEntry `
                -Path ('docs/aggregate-plus/{0:D2}.md' -f $aggregateIndex) `
                -Sha $productionBlobOid
        ))
    }
    Assert-ThrowsLike -Action {
        & $productionAggregateAtNPlusOne.Session.ReadBlob (
            New-TestTreeEntry -Path 'docs/aggregate-plus/sentinel.md' `
                -Sha $aggregateSentinelOid
        )
    }.GetNewClosure() -Pattern '*' `
        -Message "$label exact 4194304-byte aggregate ceiling was not enforced."
    try { & $productionAggregateAtNPlusOne.Session.Abort } catch { }

    [byte[]]$stderrAtNBytes = [byte[]]::new(65536)
    for ($stderrIndex = 0; $stderrIndex -lt $stderrAtNBytes.Length;
        $stderrIndex++) {
        $stderrAtNBytes[$stderrIndex] = [byte]83
    }
    $stderrAtN = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule `
        -MaximumStandardErrorBytes 65536 `
        -TransportOptions @{
            Output = $binaryResponse
            StandardError = $stderrAtNBytes
            ErrorChunkSize = 8192
        }
    [void](& $stderrAtN.Session.ReadBlob $binaryEntry)
    & $stderrAtN.Session.Complete (New-TestBatchGraphCounts `
        -ParsedBlobs 1 -ParsedBlobBytes $binaryPayload.Length)
    [byte[]]$stderrAtNPlusOneBytes = [byte[]]::new(65537)
    [Array]::Copy(
        $stderrAtNBytes, 0, $stderrAtNPlusOneBytes, 0,
        $stderrAtNBytes.Length
    )
    $stderrAtNPlusOneBytes[65536] = [byte]83
    $stderrAtNPlusOne = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule `
        -MaximumStandardErrorBytes 65536 `
        -TransportOptions @{
            Output = $binaryResponse
            StandardError = $stderrAtNPlusOneBytes
            ErrorChunkSize = 8192
        }
    Assert-ThrowsLike -Action {
        & $stderrAtNPlusOne.Session.ReadBlob $binaryEntry
    }.GetNewClosure() -Pattern '*' `
        -Message "$label stderr N+1 did not fail closed."
    Assert-True -Condition (
        [int]$stderrAtNPlusOne.Transport.State.ErrorOffset -eq 65537
    ) -Message "$label stderr overflow consumed beyond one sentinel byte."
    try { & $stderrAtNPlusOne.Session.Abort } catch { }

    foreach ($ioFaultCase in @(
        [pscustomobject]@{ Name = 'start false'; Options = @{ StartResult = $false } },
        [pscustomobject]@{ Name = 'start throw'; Options = @{ StartThrows = $true } },
        [pscustomobject]@{ Name = 'broken stdin'; Options = @{ WriteFault = $true } },
        [pscustomobject]@{ Name = 'broken flush'; Options = @{ FlushFault = $true } },
        [pscustomobject]@{ Name = 'stdout fault'; Options = @{ OutputFault = $true } }
    )) {
        $fault = New-TestActorBatchSessionFixture -Actor $Actor `
            -HostedModule $HostedModule -TransportOptions $ioFaultCase.Options
        Assert-ThrowsLike -Action {
            & $fault.Session.ReadBlob $binaryEntry
        }.GetNewClosure() -Pattern '*' `
            -Message "$label accepted $([string]$ioFaultCase.Name)."
        try { & $fault.Session.Abort } catch { }
    }

    $deadlinePassOnRead = {
        param($state)
        $state.ClockState.Value = [long]120000
    }.GetNewClosure()
    $deadlineAtN = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule -ClockValues @([long]0) `
        -TransportOptions @{
            Output = $binaryResponse
            OnOutputRead = $deadlinePassOnRead
        }
    [void](& $deadlineAtN.Session.ReadBlob $binaryEntry)
    & $deadlineAtN.Session.Complete (New-TestBatchGraphCounts `
        -ParsedBlobs 1 -ParsedBlobBytes $binaryPayload.Length)

    $deadlineFailOnRead = {
        param($state)
        $state.ClockState.Value = [long]120001
    }.GetNewClosure()
    $deadlineAtNPlusOne = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule -ClockValues @([long]0) `
        -TransportOptions @{
            Output = $binaryResponse
            PendingOutput = $true
            OnOutputRead = $deadlineFailOnRead
        }
    Assert-ThrowsLike -Action {
        & $deadlineAtNPlusOne.Session.ReadBlob $binaryEntry
    }.GetNewClosure() -Pattern '*' `
        -Message "$label deadline N+1 pending I/O did not fail closed."
    try { & $deadlineAtNPlusOne.Session.Abort } catch { }

    foreach ($clockCase in @(
        [pscustomobject]@{ Values = [long[]]@(-1) },
        [pscustomobject]@{ Values = [long[]]@(0, 1, 0) }
    )) {
        $clockFault = New-TestActorBatchSessionFixture -Actor $Actor `
            -HostedModule $HostedModule `
            -ClockValues ([long[]]$clockCase.Values) `
            -TransportOptions @{ Output = $binaryResponse }
        Assert-ThrowsLike -Action {
            & $clockFault.Session.ReadBlob $binaryEntry
        }.GetNewClosure() -Pattern '*' `
            -Message "$label accepted a negative or decreasing clock."
        try { & $clockFault.Session.Abort } catch { }
    }

    $hung = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule -TransportOptions @{
            Output = $binaryResponse
            WaitForExitResults = @($false, $true)
        }
    [void](& $hung.Session.ReadBlob $binaryEntry)
    Assert-ThrowsLike -Action {
        & $hung.Session.Complete (New-TestBatchGraphCounts `
            -ParsedBlobs 1 -ParsedBlobBytes $binaryPayload.Length)
    }.GetNewClosure() -Pattern '*' `
        -Message "$label hung child did not abort."
    try { & $hung.Session.Abort } catch { }
    Assert-True -Condition (
        [long]$hung.Transport.State.KillCalls -eq 1 -and
        [long]$hung.Transport.State.DisposeCalls -eq 1 -and
        [bool]$hung.Transport.State.HasExited -and
        $hung.Transport.State.WaitForExitMilliseconds.Count -eq 2 -and
        [int]$hung.Transport.State.WaitForExitMilliseconds[1] -eq 5000
    ) -Message "$label hung child was not killed, reaped, and disposed."

    $unreapable = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule -TransportOptions @{
            Output = $binaryResponse
            WaitForExitResults = @($false, $false)
            KillExits = $false
        }
    [void](& $unreapable.Session.ReadBlob $binaryEntry)
    Assert-ThrowsLike -Action {
        & $unreapable.Session.Complete (New-TestBatchGraphCounts `
            -ParsedBlobs 1 -ParsedBlobBytes $binaryPayload.Length)
    }.GetNewClosure() -Pattern '*' `
        -Message "$label unreapable child was accepted."
    Assert-ThrowsLike -Action {
        & $unreapable.Session.Abort
    }.GetNewClosure() -Pattern '*' `
        -Message "$label unreapable child did not report cleanup failure."

    $parityMismatch = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule -TransportOptions @{ Output = $binaryResponse }
    [void](& $parityMismatch.Session.ReadBlob $binaryEntry)
    Assert-ThrowsLike -Action {
        & $parityMismatch.Session.Complete (New-TestBatchGraphCounts `
            -ParsedBlobs 0 -ParsedBlobBytes $binaryPayload.Length)
    }.GetNewClosure() -Pattern '*' `
        -Message "$label request-count parity mismatch was accepted."
    try { & $parityMismatch.Session.Abort } catch { }
    $byteParityMismatch = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule -TransportOptions @{ Output = $binaryResponse }
    [void](& $byteParityMismatch.Session.ReadBlob $binaryEntry)
    Assert-ThrowsLike -Action {
        & $byteParityMismatch.Session.Complete (New-TestBatchGraphCounts `
            -ParsedBlobs 1 -ParsedBlobBytes ($binaryPayload.Length + 1))
    }.GetNewClosure() -Pattern '*' `
        -Message "$label response-byte parity mismatch was accepted."
    try { & $byteParityMismatch.Session.Abort } catch { }

    $reentrantState = [pscustomobject]@{
        Session = $null
        Error = $null
        Triggered = $false
    }
    $onReentrantRead = {
        param($state)
        if ($reentrantState.Triggered) { return }
        $reentrantState.Triggered = $true
        try { & $reentrantState.Session.ReadBlob $binaryEntry }
        catch { $reentrantState.Error = $_.Exception.Message }
    }.GetNewClosure()
    $reentrantFixture = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule -TransportOptions @{
            Output = $binaryResponse
            OnOutputRead = $onReentrantRead
        }
    $reentrantState.Session = $reentrantFixture.Session
    Assert-ThrowsLike -Action {
        & $reentrantState.Session.ReadBlob $binaryEntry
    }.GetNewClosure() -Pattern '*' `
        -Message "$label reentrant read was accepted."
    Assert-True -Condition (-not [string]::IsNullOrEmpty($reentrantState.Error)) `
        -Message "$label did not report the nested reentrant fault."
    try { & $reentrantFixture.Session.Abort } catch { }

    foreach ($cleanupCase in @('builder', 'validator')) {
        $cleanup = New-TestActorBatchSessionFixture -Actor $Actor `
            -HostedModule $HostedModule -TransportOptions @{ Output = $binaryResponse }
        try {
            [void](& $cleanup.Session.ReadBlob $binaryEntry)
            throw "synthetic $cleanupCase failure"
        }
        catch {
            if ($_.Exception.Message -cne "synthetic $cleanupCase failure") {
                Add-Failure "$label $cleanupCase primary fault was replaced."
            }
        }
        finally {
            try { & $cleanup.Session.Abort } catch { }
        }
        Assert-True -Condition (
            [long]$cleanup.Transport.State.KillCalls -eq 1 -and
            [long]$cleanup.Transport.State.DisposeCalls -eq 1
        ) -Message "$label $cleanupCase fault did not abort and dispose."
    }

    $primaryAndCleanup = New-TestActorBatchSessionFixture -Actor $Actor `
        -HostedModule $HostedModule -TransportOptions @{
            Output = [Text.Encoding]::ASCII.GetBytes('malformed')
            KillThrows = $true
            DisposeThrows = $true
        }
    $primaryMessage = $null
    $cleanupMessage = $null
    try { & $primaryAndCleanup.Session.ReadBlob $binaryEntry }
    catch { $primaryMessage = $_.Exception.Message }
    try { & $primaryAndCleanup.Session.Abort }
    catch { $cleanupMessage = $_.Exception.Message }
    Assert-True -Condition (
        -not [string]::IsNullOrEmpty($primaryMessage) -and
        $primaryMessage -match '(?i)(response|header|protocol|blob)' -and
        -not [string]::IsNullOrEmpty($cleanupMessage) -and
        $cleanupMessage -match '(?i)(kill|dispose)'
    ) -Message "$label cleanup fault hid the primary protocol failure."
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
    $quickBatchContractPasses = Test-InstructionGraphBatchActorSourceContract `
        -ActorLabel 'quick-adoption' -ActorPath $quickAssessmentPath `
        -FactoryName 'New-QuickAdoptionInstructionGraphBatchSession' `
        -GraphEntryName 'Get-QuickAdoptionInstructionGraph' `
        -LegacyBlobReaderName 'Get-QuickAdoptionInstructionGraphBlobBytes'
    $hostedBatchContractPasses = Test-InstructionGraphBatchActorSourceContract `
        -ActorLabel 'hosted-bootstrap' -ActorPath $hostedAdapterPath `
        -FactoryName 'New-InstructionGraphBatchSession' `
        -GraphEntryName 'Get-InstructionGraphForCommit' `
        -LegacyBlobReaderName 'Get-InstructionGraphBlobBytes'

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

        $hostedAcquisitionModule = $null
        try {
            $hostedAcquisitionModule = New-TestHostedGraphAcquisitionModule `
                -AdapterPath $hostedAdapterPath -PolicyModulePath $modulePath
        }
        catch {
            Add-Failure (
                'TEST-0161 hosted actor dependency extraction failed: ' +
                $_.Exception.Message
            )
        }
        if ($quickBatchContractPasses -and
            $hostedBatchContractPasses -and
            $null -ne $hostedAcquisitionModule) {
            Test-InstructionGraphBatchActorBehavior -Actor quick `
                -HostedModule $hostedAcquisitionModule `
                -GraphBuilder $graphBuilder -GraphValidator $graphValidator
            Test-InstructionGraphBatchActorBehavior -Actor hosted `
                -HostedModule $hostedAcquisitionModule `
                -GraphBuilder $graphBuilder -GraphValidator $graphValidator
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
            '7da1bf35db9db45dbbf70ff777c02ac4c58619dab4a2d1ad5efb969b3c6b2950') `
            -Message "TEST-0151 fixed graph digest differs across supported hosts: $([string]$graph.digest)."
        $compactGraphJson = $graph | ConvertTo-Json -Depth 20 -Compress
        $compactGraphJsonSha = & $getSha256Action -Bytes (
            [Text.UTF8Encoding]::new($false).GetBytes($compactGraphJson)
        )
        Assert-True -Condition ($compactGraphJsonSha -ceq `
            '31955e351e5921cd5ee23aee4a8ef4d094d1ca0c3cecb38b5df54252b73a411e') `
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

        $structuredPayloadFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = @'
See [migration definition](migrations/MIG-0001.json).
'@
            'migrations/MIG-0001.json' = @'
{
  "after": "[pinned canonical idea template](../../.ai/protocol/templates/idea.md)",
  "directive": "Required reading: `docs/STRUCTURED-AUTHORITY.md`."
}
'@
            '.github/instructions/root.json' = @'
{
  "directive": "Required reading: [root authority](../../docs/ROOT-JSON-AUTHORITY.md)."
}
'@
            'docs/ROOT-JSON-AUTHORITY.md' =
                'Authority linked by a declared JSON instruction root.'
        })
        $structuredPayloadGraph = & $graphBuilder -BaseHead ('0' * 40) `
            -TreeEntries $structuredPayloadFixture.Entries `
            -ReadBlob $structuredPayloadFixture.Reader
        Assert-True -Condition (
            @($structuredPayloadGraph.nodes.path) -ccontains
                'migrations/MIG-0001.json' -and
            @($structuredPayloadGraph.nodes.path) -cnotcontains
                'docs/STRUCTURED-AUTHORITY.md' -and
            @($structuredPayloadGraph.edges | Where-Object {
                $_.source -ceq '.github/instructions/root.json' -and
                $_.target -ceq 'docs/ROOT-JSON-AUTHORITY.md' -and
                $_.kind -ceq 'RequiresRead' -and
                $_.reason -ceq 'MarkdownLink'
            }).Count -eq 1 -and
            @($structuredPayloadGraph.edges | Where-Object {
                $_.source -ceq 'migrations/MIG-0001.json' -and
                $_.target -like '*templates/idea.md*'
            }).Count -eq 0
        ) -Message 'TEST-0151 structured JSON payload masking promoted inert data or suppressed root instructions.'

        $jsonMarkdownEscapeFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' =
                'See [ordinary Markdown](docs/JSON-looking.md).'
            'docs/JSON-looking.md' =
                '{ "after": [escape](../../outside.md) }'
        })
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('0' * 40) `
                -TreeEntries $jsonMarkdownEscapeFixture.Entries `
                -ReadBlob $jsonMarkdownEscapeFixture.Reader
        } -Pattern '*escapes the repository root*' `
            -Message 'TEST-0152 JSON-looking prose in Markdown bypassed path-containment validation.'

        $rootJsonEscapeFixture = New-TestGraphFixture -Files ([ordered]@{
            '.github/instructions/root.json' = @'
{
  "directive": "Required reading: [escape](../../../outside.md)."
}
'@
        })
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('0' * 40) `
                -TreeEntries $rootJsonEscapeFixture.Entries `
                -ReadBlob $rootJsonEscapeFixture.Reader
        } -Pattern '*escapes the repository root*' `
            -Message 'TEST-0152 JSON instruction-root masking bypassed path-containment validation.'

        $unterminatedJsonFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = 'See [data](docs/data.json).'
            'docs/data.json' = '{ "after": "unterminated'
        })
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('0' * 40) `
                -TreeEntries $unterminatedJsonFixture.Entries `
                -ReadBlob $unterminatedJsonFixture.Reader
        } -Pattern '*Instruction JSON string*unterminated*' `
            -Message 'TEST-0152 malformed JSON string masking did not fail closed.'

        $controlJsonFixture = New-TestGraphFixture -Files ([ordered]@{
            'AGENTS.md' = 'See [data](docs/data.json).'
            'docs/data.json' =
                '{ "after": "raw' + [char]0x09 + 'control" }'
        })
        Assert-ThrowsLike -Action {
            & $graphBuilder -BaseHead ('0' * 40) `
                -TreeEntries $controlJsonFixture.Entries `
                -ReadBlob $controlJsonFixture.Reader
        } -Pattern '*Instruction JSON string*unescaped control character*' `
            -Message 'TEST-0152 unescaped JSON control character did not fail closed.'

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

            $originalAgentsOid = [string]@(
                Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                    -Arguments @('rev-parse', "$realGitHead`:AGENTS.md")
            )[0].Trim()
            $replacementAgentsText = @(
                '# Replacement-only instructions',
                '',
                'Required reading: [replacement](docs/REPLACED_ONLY.md).',
                ''
            ) -join "`n"
            $replacementPayloadPath = Join-Path $realGitRoot `
                '.replacement-agents-payload'
            Set-TestFixtureBytes -Path $replacementPayloadPath `
                -Bytes $fixtureUtf8.GetBytes($replacementAgentsText)
            $replacementAgentsOid = [string]@(
                Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                    -Arguments @(
                        'hash-object', '-w', '--', $replacementPayloadPath
                    )
            )[0].Trim()
            Remove-Item -LiteralPath $replacementPayloadPath -Force
            [void](Invoke-TestGitCommand -RepositoryRoot $realGitRoot `
                -Arguments @(
                    'replace', $originalAgentsOid, $replacementAgentsOid
                ))
            [byte[]]$replaceEnabledAgentsBlob = Invoke-TestGitBytes `
                -WorkingDirectory $realGitRoot `
                -Arguments "cat-file blob $originalAgentsOid"
            [byte[]]$replaceDisabledAgentsBlob = Invoke-TestGitBytes `
                -WorkingDirectory $realGitRoot `
                -Arguments "cat-file blob $originalAgentsOid" `
                -DisableReplaceObjects
            Assert-True -Condition (
                (& $getSha256Action -Bytes $replaceEnabledAgentsBlob) -ceq
                    (& $getSha256Action -Bytes (
                        $fixtureUtf8.GetBytes($replacementAgentsText)
                    )) -and
                (& $getSha256Action -Bytes $replaceDisabledAgentsBlob) -ceq
                    (& $getSha256Action -Bytes (
                        $fixtureUtf8.GetBytes($committedAgentsText)
                    ))
            ) -Message 'TEST-0161 real-Git replace ref was not active or could not be disabled at the child boundary.'

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
            $hostedEntries = @(& $hostedAcquisitionModule {
                param($repository, $commit)
                @(Get-InstructionGraphTreeEntries -Repository $repository `
                    -Commit $commit)
            } $realGitRoot $realGitHead)
            $realBatchArguments = [ordered]@{
                Repository = $realGitRoot
                MaximumBlobBytes = [long]262144
                MaximumAggregateBlobBytes = [long]4194304
                SessionTimeoutMilliseconds = [int]120000
                AbortTimeoutMilliseconds = [int]5000
                MaximumHeaderBytes = [int]128
                MaximumStandardErrorBytes = [int]65536
            }
            $realPositiveEntries = @(
                $quickEntries | Where-Object {
                    $_.Path -in @('AGENTS.md', 'docs/AUTHORITY.md')
                } | Sort-Object Path
            )
            foreach ($streamFaultActor in @(
                [pscustomobject]@{
                    Path = $quickAssessmentPath
                    Factory =
                        'New-QuickAdoptionInstructionGraphBatchSession'
                },
                [pscustomobject]@{
                    Path = $hostedAdapterPath
                    Factory = 'New-InstructionGraphBatchSession'
                }
            )) {
                $faultFactory = $null
                $faultSession = $null
                try {
                    $faultFactory =
                        New-TestStreamCaptureFaultFactoryModule `
                            -ActorPath $streamFaultActor.Path `
                            -FactoryName $streamFaultActor.Factory
                    $faultSession = & $faultFactory.Module {
                        param($factoryName, $factoryArguments)
                        & $factoryName @factoryArguments
                    } $faultFactory.FactoryName $realBatchArguments
                    Assert-ThrowsLike -Action {
                        & $faultSession.ReadBlob $realPositiveEntries[0]
                    }.GetNewClosure() `
                        -Pattern '*synthetic stream-capture failure*' `
                        -Message 'TEST-0161 stream-capture failure did not fail closed.'
                }
                finally {
                    if ($null -ne $faultSession) {
                        try { & $faultSession.Abort } catch {
                            Add-Failure (
                                'TEST-0161 stream-capture cleanup failed: ' +
                                $_.Exception.Message
                            )
                        }
                    }
                    if ($null -ne $faultFactory) {
                        Remove-Module $faultFactory.Module -Force
                    }
                }
            }
            $actorObservations = @{}
            $originalConsoleInputEncoding = [Console]::InputEncoding
            try {
                # A preamble-bearing ambient encoding reproduces the PS5.1
                # StreamWriter-close hazard. The production actor must remain
                # exact because it closes only the raw BaseStream pipe.
                [Console]::InputEncoding =
                    [Text.UnicodeEncoding]::new($false, $true)
                Assert-True -Condition (
                    [Console]::InputEncoding.GetPreamble().Length -gt 0
                ) -Message 'TEST-0161 ambient stdin encoding has no preamble.'
                foreach ($realActor in @('quick', 'hosted')) {
                    $realSession = Invoke-TestActorBatchFactory `
                        -Actor $realActor `
                        -HostedModule $hostedAcquisitionModule `
                        -Arguments $realBatchArguments
                    [long]$realResponseBytes = 0
                    $realSessionCompleted = $false
                    try {
                        foreach ($realEntry in $realPositiveEntries) {
                            [byte[]]$realBytes =
                                & $realSession.ReadBlob $realEntry
                            $realResponseBytes += $realBytes.Length
                        }
                        & $realSession.Complete (New-TestBatchGraphCounts `
                            -ParsedBlobs $realPositiveEntries.Count `
                            -ParsedBlobBytes $realResponseBytes)
                        $realSessionCompleted = $true
                        $actorObservations[$realActor] =
                            & $realSession.GetObservation
                    }
                    finally {
                        if (-not $realSessionCompleted) {
                            try { & $realSession.Abort } catch { }
                        }
                    }
                }
            }
            finally {
                [Console]::InputEncoding = $originalConsoleInputEncoding
            }
            [long]$quickBatchStarts =
                [long]$actorObservations.quick.ProcessStarts
            [long]$hostedBatchStarts =
                [long]$actorObservations.hosted.ProcessStarts
            [long]$quickBatchRequests =
                [long]$actorObservations.quick.Requests
            [long]$hostedBatchRequests =
                [long]$actorObservations.hosted.Requests
            Assert-True -Condition (
                $quickBatchStarts -eq 1 -and $quickBatchRequests -eq 2
            ) -Message 'TEST-0161 quick real-Git acquisition was not exactly one batch process and two requests.'
            Assert-True -Condition (
                $hostedBatchStarts -eq 1 -and $hostedBatchRequests -eq 2
            ) -Message 'TEST-0161 hosted real-Git acquisition was not exactly one batch process and two requests.'
            $script:InstructionGraphBlobProcessStarts =
                $quickBatchStarts + $hostedBatchStarts
            $script:InstructionGraphBlobRequests =
                $quickBatchRequests + $hostedBatchRequests
            $quickGraph = Get-QuickAdoptionInstructionGraph `
                -Repository $realGitRoot -Commit $realGitHead
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
            $expectedAgentsBlob = $fixtureUtf8.GetBytes($committedAgentsText)
            Assert-True -Condition (
                [string]$quickAgentsEntry.Sha -ceq $originalAgentsOid -and
                (& $getSha256Action -Bytes $replaceDisabledAgentsBlob) -ceq
                    (& $getSha256Action -Bytes $expectedAgentsBlob) -and
                (& $getSha256Action -Bytes $worktreeAgentsBytes) -cne
                    (& $getSha256Action -Bytes $expectedAgentsBlob)
            ) -Message 'TEST-0152 independent exact reader or tree identity used replace/filter/worktree bytes.'
            Assert-True -Condition (
                [string]$quickGraph.digest -ceq [string]$hostedGraph.digest -and
                [string]$quickGraph.baseHead -ceq $realGitHead -and
                @($quickGraph.nodes.path) -ccontains 'docs/AUTHORITY.md' -and
                @($quickGraph.nodes.path) -cnotcontains 'docs/REPLACED_ONLY.md' -and
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
            [int]$limits.MaximumNodes -eq 512 -and
            [int]$limits.MaximumEdges -eq 4096 -and
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
        $aliasSha = & $getGitBlobSha1Action -Bytes $aliasBytes
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
        $treeRootSha = & $getGitBlobSha1Action -Bytes $treeRootBytes
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
            -Sha (Get-MeAndAIGitBlobSha1 -Bytes $treePathRootBytes)))
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
            New-TestTreeEntry -Path (
                'docs/features/N{0:D3}.md' -f $nodeAtLimit.Count
            )
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
        $originalSelfFixtureInputEncoding = [Console]::InputEncoding
        $selfFixture = $null
        $selfReaderCompleted = $false
        try {
            [Console]::InputEncoding = [Text.UTF8Encoding]::new($true)
            $ambientPreamble = [Console]::InputEncoding.GetPreamble()
            Assert-True -Condition (
                $ambientPreamble.Length -eq 3 -and
                $ambientPreamble[0] -eq 0xEF -and
                $ambientPreamble[1] -eq 0xBB -and
                $ambientPreamble[2] -eq 0xBF
            ) -Message 'TEST-0152 ambient stdin encoding lacks the UTF-8 preamble.'
            $selfFixture = Get-TestCommittedGraphFixture `
                -RepositoryRoot $root -BaseHead $head
            $selfGraph = & $graphBuilder -BaseHead $head `
                -TreeEntries $selfFixture.Entries -ReadBlob $selfFixture.Reader
            $restoredPreamble = [Console]::InputEncoding.GetPreamble()
            Assert-True -Condition (
                $restoredPreamble.Length -eq 3 -and
                $restoredPreamble[0] -eq 0xEF -and
                $restoredPreamble[1] -eq 0xBB -and
                $restoredPreamble[2] -eq 0xBF
            ) -Message (
                'TEST-0152 independent expected reader did not restore the ' +
                'preamble-bearing ambient stdin encoding.'
            )
            & $selfFixture.Complete
            $selfReaderCompleted = $true
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
        finally {
            if ($null -ne $selfFixture -and -not $selfReaderCompleted) {
                & $selfFixture.Abort
            }
            [Console]::InputEncoding = $originalSelfFixtureInputEncoding
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Instruction-graph discovery tests failed with $($failures.Count) problem(s):" `
        -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0161'
Write-Host 'Instruction-graph discovery tests passed.' -ForegroundColor Green
$scenarioResult = New-MeAndAIScenarioResult -Owner $owner `
    -SourcePaths @($PSCommandPath) -AuthorityPath $scenarioAuthorityPath
$scenarioLine = 'MEANDAI_SCENARIO_RESULTS=' +
    ($scenarioResult | ConvertTo-Json -Compress)
$operationLine = Format-MeAndAITestOperationObservation `
    -Owner $operationExpectation.Owner -Route $operationExpectation.Route `
    -Runtime $operationExpectation.Runtime -Counters @(
        [ordered]@{
            name = 'instruction-graph.blob-process-start'
            actual = [long]$script:InstructionGraphBlobProcessStarts
            maximum = [long]$operationExpectation.Counters[0].Maximum
        },
        [ordered]@{
            name = 'instruction-graph.blob-request'
            actual = [long]$script:InstructionGraphBlobRequests
            maximum = [long]$operationExpectation.Counters[1].Maximum
        }
    )
$operationRecord = Read-MeAndAITestOperationObservationRecord `
    -Output @($operationLine, $scenarioLine) `
    -ExpectedOwner $operationExpectation.Owner `
    -ExpectedRoute $operationExpectation.Route `
    -ExpectedRuntime $operationExpectation.Runtime `
    -ExpectedCounters @($operationExpectation.Counters)
if (-not $operationRecord.Valid) {
    throw "Instruction-graph operation evidence is invalid: $($operationRecord.Message)"
}
Write-Host $operationLine
Write-Host $scenarioLine
