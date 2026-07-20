$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$owner = 'tests/capabilities/initial-adoption/quick-adoption-bundle.tests.ps1'
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force

$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([Parameter(Mandatory)][string]$Message)
    $failures.Add($Message)
}

function Get-RelativeFileText {
    param([Parameter(Mandatory)][string]$RelativePath)
    $path = Join-Path $root ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "TEST-0147 required modular quick-adoption source is missing: $RelativePath"
        return ''
    }
    return Get-Content -LiteralPath $path -Raw
}

function New-TestRuntimeBundle {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$SourceCommit,
        [string]$ExtraEntry = '',
        [switch]$TrailingDotCollision,
        [string]$ManifestSourceCommit = '',
        [switch]$BadPayloadDigest
    )

    $moduleSource = @'
function Invoke-MeAndAIQuickAdoption {
    param([string]$TargetPath = '.', [string]$ProtocolTag = 'v0.12.4')
    [IO.File]::WriteAllText(
        $env:MEANDAI_TEST_RUNTIME_SENTINEL,
        "$TargetPath`n$ProtocolTag",
        [Text.UTF8Encoding]::new($false)
    )
}
Export-ModuleMember -Function 'Invoke-MeAndAIQuickAdoption'
'@
    $moduleManifest = @'
@{
    RootModule = 'MeAndAI.QuickAdoption.psm1'
    ModuleVersion = '0.12.4'
    GUID = '04ed28e4-4f2c-4ec0-9497-d81487d114ec'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Invoke-MeAndAIQuickAdoption')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
'@
    $utf8 = [Text.UTF8Encoding]::new($false)
    $files = [ordered]@{
        'MeAndAI.QuickAdoption/MeAndAI.QuickAdoption.psd1' = $utf8.GetBytes($moduleManifest)
        'MeAndAI.QuickAdoption/MeAndAI.QuickAdoption.psm1' = $utf8.GetBytes($moduleSource)
    }
    if ($TrailingDotCollision) {
        $files.Add(
            'MeAndAI.QuickAdoption/Private/collision.ps1',
            [byte[]](1, 2, 3)
        )
        $files.Add(
            'MeAndAI.QuickAdoption/Private/collision.ps1.',
            [byte[]](4, 5, 6)
        )
    }
    $payload = @($files.GetEnumerator() | ForEach-Object {
        [ordered]@{
            path = [string]$_.Key
            length = [long]$_.Value.LongLength
            sha256 = (Get-FileDigest -Bytes ([byte[]]$_.Value))
        }
    })
    if ($BadPayloadDigest) {
        $payload[0].sha256 = 'f' * 64
    }
    $manifest = [ordered]@{
        schema = 1
        kind = 'meandai.quick-adoption.module-bundle'
        runtimeRepository = 'hasanmanzak/meAndAI'
        runtimeReleaseTag = 'v0.12.4'
        sourceCommit = if ($ManifestSourceCommit) {
            $ManifestSourceCommit
        }
        else { $SourceCommit }
        entryPoint = 'MeAndAI.QuickAdoption/MeAndAI.QuickAdoption.psd1'
        minimumPowerShellVersion = '5.1'
        payload = $payload
    }
    $manifestBytes = $utf8.GetBytes(
        ($manifest | ConvertTo-Json -Depth 8 -Compress)
    )
    Add-Type -AssemblyName System.IO.Compression
    $stream = [IO.File]::Open(
        $Path, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None
    )
    $archive = $null
    try {
        $archive = [IO.Compression.ZipArchive]::new(
            $stream, [IO.Compression.ZipArchiveMode]::Create, $false,
            [Text.Encoding]::UTF8
        )
        foreach ($item in @(
            [pscustomobject]@{ Path = 'manifest.json'; Bytes = $manifestBytes }
        ) + @($files.GetEnumerator() | ForEach-Object {
            [pscustomobject]@{ Path = [string]$_.Key; Bytes = [byte[]]$_.Value }
        }) + @(if ($ExtraEntry) {
            [pscustomobject]@{ Path = $ExtraEntry; Bytes = [byte[]](1, 2, 3) }
        })) {
            $entry = $archive.CreateEntry(
                [string]$item.Path,
                [IO.Compression.CompressionLevel]::NoCompression
            )
            $entry.LastWriteTime = [DateTimeOffset]::new(
                1980, 1, 1, 0, 0, 0, [TimeSpan]::Zero
            )
            $entryStream = $entry.Open()
            try {
                $bytes = [byte[]]$item.Bytes
                $entryStream.Write($bytes, 0, $bytes.Length)
            }
            finally { $entryStream.Dispose() }
        }
    }
    finally {
        if ($null -ne $archive) { $archive.Dispose() }
        $stream.Dispose()
    }
}

function Get-FileDigest {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($algorithm.ComputeHash($Bytes)) `
            -replace '-', '').ToLowerInvariant()
    }
    finally { $algorithm.Dispose() }
}

function Read-TestTrackedBlob {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Commit,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $gitCommand = (Get-Command git -CommandType Application -ErrorAction Stop |
        Select-Object -First 1).Source
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $gitCommand
    $startInfo.Arguments = "cat-file blob $Commit`:$RelativePath"
    $startInfo.WorkingDirectory = $Repository
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $memory = [IO.MemoryStream]::new()
    $started = $false
    try {
        if (-not $process.Start()) {
            throw "Unable to start exact Git blob read for '$RelativePath'."
        }
        $started = $true
        $buffer = [byte[]]::new(81920)
        while (($read = $process.StandardOutput.BaseStream.Read(
            $buffer, 0, $buffer.Length
        )) -gt 0) {
            $memory.Write($buffer, 0, $read)
        }
        $errorText = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            throw "Unable to read exact Git blob '$RelativePath': $errorText"
        }
        return ,$memory.ToArray()
    }
    finally {
        if ($started -and -not $process.HasExited) { $process.Kill() }
        $memory.Dispose()
        $process.Dispose()
    }
}

function Get-PublicParameterContract {
    param(
        [Parameter(Mandatory)][string]$Source,
        [string]$FunctionName = ''
    )
    $tokens = $null
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseInput(
        $Source, [ref]$tokens, [ref]$errors
    )
    if ($errors.Count -ne 0) {
        throw "Parameter-contract source does not parse: $($errors[0].Message)"
    }
    $paramBlock = if ($FunctionName) {
        $functions = @($ast.FindAll({
            param($node)
            $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -ceq $FunctionName
        }, $true))
        if ($functions.Count -ne 1) {
            throw "Function '$FunctionName' is missing or ambiguous."
        }
        $functions[0].Body.ParamBlock
    }
    else { $ast.ParamBlock }
    return @($paramBlock.Parameters | ForEach-Object {
        [pscustomobject]@{
            Name = $_.Name.VariablePath.UserPath
            Type = $_.StaticType.FullName
            Attributes = @($_.Attributes | ForEach-Object {
                ($_.Extent.Text -replace '\s+', '')
            }) -join '|'
            Default = if ($null -ne $_.DefaultValue) {
                ($_.DefaultValue.Extent.Text -replace '\s+', '')
            }
            else { '' }
        }
    })
}

$bootstrapRelativePath = 'scripts/Invoke-MeAndAIQuickAdoption.ps1'
$builderRelativePath = 'scripts/Build-MeAndAIQuickAdoptionBundle.ps1'
$inventoryRelativePath = 'scripts/quick-adoption/bundle.sources.json'
$moduleRelativePaths = @(
    'scripts/quick-adoption/MeAndAI.QuickAdoption.psd1',
    'scripts/quick-adoption/MeAndAI.QuickAdoption.psm1',
    'scripts/quick-adoption/Private/Configuration.ps1',
    'scripts/quick-adoption/Private/OutputAndNativeProcess.ps1',
    'scripts/quick-adoption/Private/RepositoryAssessment.ps1',
    'scripts/quick-adoption/Private/ProtocolReleaseAndAssets.ps1',
    'scripts/quick-adoption/Private/ProposalOwnership.ps1',
    'scripts/quick-adoption/Private/CodexRuntime.ps1',
    'scripts/quick-adoption/Private/CompletionAndPublication.ps1',
    'scripts/quick-adoption/Public/Invoke-MeAndAIQuickAdoption.ps1'
)
$allSourcePaths = @(
    $bootstrapRelativePath,
    $builderRelativePath,
    $inventoryRelativePath
) + $moduleRelativePaths

$sourceByPath = @{}
foreach ($relativePath in $allSourcePaths) {
    $sourceByPath[$relativePath] = Get-RelativeFileText -RelativePath $relativePath
}

$bootstrap = [string]$sourceByPath[$bootstrapRelativePath]
if ($bootstrap) {
    $lineCount = @($bootstrap -split '\r?\n').Count
    if ($lineCount -gt 900 -or [Text.Encoding]::UTF8.GetByteCount($bootstrap) -gt 50000) {
        Add-Failure "TEST-0147 thin bootstrapper exceeds its bounded review surface: $lineCount lines."
    }
    foreach ($required in @(
        "`$runtimeReleaseTag = 'v0.12.4'",
        "`$runtimeBundleAssetName = 'MeAndAI.QuickAdoption.Bundle.zip'",
        '$runtimeBundleMaximumArchiveBytes = 67108864',
        '$runtimeBundleMaximumExpandedBytes = 67108864',
        'immutable', 'digest', 'sourceCommit', 'entryPoint',
        'GH_HOST', 'Assert-QuickAdoptionBootstrapNoReparseAncestor',
        'Import-Module', 'Remove-Module'
    )) {
        if (-not $bootstrap.Contains($required)) {
            Add-Failure "TEST-0147 thin bootstrapper is missing trust or lifecycle contract '$required'."
        }
    }
    foreach ($forbidden in @('Invoke-Expression', 'iex ', '| powershell', '| pwsh')) {
        if ($bootstrap.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            Add-Failure "TEST-0147 thin bootstrapper contains forbidden execution surface '$forbidden'."
        }
    }
    $ghDiscovery = $bootstrap.LastIndexOf(
        'Get-Command gh -CommandType Application',
        [StringComparison]::Ordinal
    )
    $versionPreflight = $bootstrap.LastIndexOf(
        'Assert-QuickAdoptionBootstrapGitHubCliVersion',
        [StringComparison]::Ordinal
    )
    $credentialRead = $bootstrap.LastIndexOf(
        'Read-QuickAdoptionBootstrapProtocolToken -Root',
        [StringComparison]::Ordinal
    )
    $temporaryRootSelection = $bootstrap.LastIndexOf(
        '$temporaryRoot = Get-QuickAdoptionBootstrapTemporaryRoot',
        [StringComparison]::Ordinal
    )
    $hostPin = $bootstrap.LastIndexOf(
        "'GH_HOST', 'github.com'", [StringComparison]::Ordinal
    )
    $authentication = $bootstrap.LastIndexOf(
        'Assert-QuickAdoptionBootstrapGitHubAuthentication',
        [StringComparison]::Ordinal
    )
    if ($ghDiscovery -lt 0 -or $versionPreflight -le $ghDiscovery -or
        $credentialRead -le $versionPreflight -or
        $temporaryRootSelection -le $credentialRead -or
        $hostPin -le $temporaryRootSelection -or
        $authentication -le $hostPin) {
        Add-Failure 'TEST-0147 bootstrap prerequisite, credential, host-pin, and authentication order is unsafe.'
    }
    try {
        $bootstrapContract = @(Get-PublicParameterContract -Source $bootstrap)
        $publicContract = @(Get-PublicParameterContract `
            -Source ([string]$sourceByPath['scripts/quick-adoption/Public/Invoke-MeAndAIQuickAdoption.ps1']) `
            -FunctionName 'Invoke-MeAndAIQuickAdoption')
        $bootstrapJson = $bootstrapContract | ConvertTo-Json -Depth 5 -Compress
        $publicJson = $publicContract | ConvertTo-Json -Depth 5 -Compress
        if ($bootstrapJson -cne $publicJson) {
            Add-Failure 'TEST-0147 thin bootstrap and module entry point parameter contracts differ.'
        }
    }
    catch {
        Add-Failure "TEST-0147 public parameter parity could not be verified: $($_.Exception.Message)"
    }
}

foreach ($relativePath in @($bootstrapRelativePath, $builderRelativePath) + $moduleRelativePaths) {
    $text = [string]$sourceByPath[$relativePath]
    if (-not $text) { continue }
    $tokens = $null
    $parseErrors = $null
    [void][Management.Automation.Language.Parser]::ParseInput(
        $text, [ref]$tokens, [ref]$parseErrors
    )
    if (@($parseErrors).Count -ne 0) {
        Add-Failure "TEST-0147 PowerShell source '$relativePath' does not parse: $($parseErrors[0].Message)"
    }
}

$inventoryText = [string]$sourceByPath[$inventoryRelativePath]
if ($inventoryText) {
    try {
        $inventory = $inventoryText | ConvertFrom-Json
        $properties = @($inventory.PSObject.Properties | ForEach-Object { [string]$_.Name })
        if (($properties -join ',') -cne 'schema,kind,entryPoint,sources') {
            Add-Failure 'TEST-0147 bundle source inventory does not have the exact canonical property order.'
        }
        if ([long]$inventory.schema -ne 1 -or
            [string]$inventory.kind -cne 'meandai.quick-adoption.bundle-sources' -or
            [string]$inventory.entryPoint -cne 'MeAndAI.QuickAdoption/MeAndAI.QuickAdoption.psd1') {
            Add-Failure 'TEST-0147 bundle source inventory identity is invalid.'
        }
        $expectedBundleSources = @($moduleRelativePaths | ForEach-Object {
            ($_ -replace '^scripts/quick-adoption/', 'MeAndAI.QuickAdoption/')
        })
        $actualBundleSources = @($inventory.sources | ForEach-Object { [string]$_ })
        if (($actualBundleSources -join "`n") -cne ($expectedBundleSources -join "`n")) {
            Add-Failure 'TEST-0147 bundle source inventory is not the exact ordered module payload.'
        }
        $loaderText = [string]$sourceByPath[
            'scripts/quick-adoption/MeAndAI.QuickAdoption.psm1'
        ]
        $loaderSources = @([regex]::Matches(
            $loaderText,
            "'(?<path>(?:Private|Public)/[A-Za-z0-9_.-]+\.ps1)'",
            [Text.RegularExpressions.RegexOptions]::CultureInvariant
        ) | ForEach-Object { $_.Groups['path'].Value })
        $expectedLoaderSources = @($actualBundleSources | Select-Object -Skip 2 |
            ForEach-Object {
                $_.Substring('MeAndAI.QuickAdoption/'.Length)
            })
        if (($loaderSources -join "`n") -cne ($expectedLoaderSources -join "`n")) {
            Add-Failure 'TEST-0147 module loader order differs from the canonical bundle inventory.'
        }
    }
    catch {
        Add-Failure "TEST-0147 bundle source inventory is not valid canonical JSON: $($_.Exception.Message)"
    }
}

$trackedArchive = @(git -C $root ls-files -- 'scripts/*.zip' 'scripts/quick-adoption/*.zip')
if ($LASTEXITCODE -ne 0 -or $trackedArchive.Count -ne 0) {
    Add-Failure 'TEST-0147 a generated quick-adoption bundle is tracked or archive inventory failed.'
}

$moduleManifestPath = Join-Path $root 'scripts/quick-adoption/MeAndAI.QuickAdoption.psd1'
$modulePath = Join-Path $root 'scripts/quick-adoption/MeAndAI.QuickAdoption.psm1'
if ((Test-Path -LiteralPath $moduleManifestPath -PathType Leaf) -and
    (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    $beforeLocation = (Get-Location).Path
    $module = $null
    try {
        $module = Import-Module -Name $moduleManifestPath -Force -PassThru
        $exports = @($module.ExportedCommands.Keys | Sort-Object)
        if (($exports -join ',') -cne 'Invoke-MeAndAIQuickAdoption') {
            Add-Failure "TEST-0147 module exports an unexpected command set: $($exports -join ', ')."
        }
        if ((Get-Location).Path -cne $beforeLocation) {
            Add-Failure 'TEST-0147 module import changed the caller working directory.'
        }
    }
    catch {
        Add-Failure "TEST-0147 module import failed: $($_.Exception.Message)"
    }
    finally {
        if ($null -ne $module) { Remove-Module -ModuleInfo $module -Force }
        Set-Location -LiteralPath $beforeLocation
    }
}

$builderPath = Join-Path $root 'scripts/Build-MeAndAIQuickAdoptionBundle.ps1'
if (Test-Path -LiteralPath $builderPath -PathType Leaf) {
    $fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) `
        ('meandai-bundle-test-' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $fixtureRoot)
    try {
        $sourceRoot = Join-Path $fixtureRoot 'source'
        $sourceScripts = Join-Path $sourceRoot 'scripts'
        [void](New-Item -ItemType Directory -Path $sourceScripts -Force)
        Copy-Item -LiteralPath (Join-Path $root 'scripts/quick-adoption') `
            -Destination $sourceScripts -Recurse
        $fixtureBuilderPath = Join-Path $sourceScripts `
            'Build-MeAndAIQuickAdoptionBundle.ps1'
        Copy-Item -LiteralPath $builderPath -Destination $fixtureBuilderPath
        $transformRelativePath =
            'scripts/quick-adoption/Private/Configuration.ps1'
        $transformPath = Join-Path $sourceRoot `
            ($transformRelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
        $initialTransformText = [IO.File]::ReadAllText($transformPath).Replace(
            "`r`n", "`n"
        ).Replace("`r", "`n")
        [IO.File]::WriteAllText(
            $transformPath, $initialTransformText.Replace("`n", "`r`n"),
            [Text.UTF8Encoding]::new($false)
        )
        [IO.File]::WriteAllText(
            (Join-Path $sourceRoot '.gitattributes'),
            "$transformRelativePath text eol=crlf`n",
            [Text.UTF8Encoding]::new($false)
        )

        $previousPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            & git -C $sourceRoot init -q
            if ($LASTEXITCODE -ne 0) { throw 'Unable to initialize bundle source fixture.' }
            & git -C $sourceRoot config user.name 'meAndAI TEST-0147'
            if ($LASTEXITCODE -ne 0) { throw 'Unable to configure bundle fixture author.' }
            & git -C $sourceRoot config user.email 'test-0147@invalid.example'
            if ($LASTEXITCODE -ne 0) { throw 'Unable to configure bundle fixture email.' }
            & git -C $sourceRoot config commit.gpgsign false
            if ($LASTEXITCODE -ne 0) { throw 'Unable to disable fixture commit signing.' }
            & git -C $sourceRoot config core.autocrlf false
            if ($LASTEXITCODE -ne 0) { throw 'Unable to pin fixture blob bytes.' }
            & git -C $sourceRoot add -- .gitattributes scripts/quick-adoption `
                scripts/Build-MeAndAIQuickAdoptionBundle.ps1
            if ($LASTEXITCODE -ne 0) { throw 'Unable to stage bundle fixture sources.' }
            & git -C $sourceRoot commit -q -m 'TEST-0147 bundle source fixture'
            if ($LASTEXITCODE -ne 0) { throw 'Unable to commit bundle fixture sources.' }
            $sourceCommit = (@(& git -C $sourceRoot rev-parse HEAD) -join '').Trim()
            if ($LASTEXITCODE -ne 0 -or $sourceCommit -cnotmatch '^[0-9a-f]{40}$') {
                throw 'Unable to resolve bundle fixture source commit.'
            }
        }
        finally { $ErrorActionPreference = $previousPreference }

        $transformBlobBytes = Read-TestTrackedBlob -Repository $sourceRoot `
            -Commit $sourceCommit -RelativePath $transformRelativePath
        $transformWorktreeBytes = [IO.File]::ReadAllBytes($transformPath)
        $transformStatus = @(& git -C $sourceRoot status --porcelain=v1 `
            --untracked-files=all)
        if (($transformStatus -join '').Length -ne 0 -or
            (Get-FileDigest -Bytes $transformBlobBytes) -ceq
                (Get-FileDigest -Bytes $transformWorktreeBytes)) {
            throw 'Transform-sensitive fixture did not preserve a clean tree with distinct Git-blob bytes.'
        }

        $first = Join-Path $fixtureRoot 'first.zip'
        $second = Join-Path $fixtureRoot 'second.zip'
        $defaultRoot = Join-Path $fixtureRoot 'default-root.zip'
        [void](& $builderPath -SourceRoot $sourceRoot `
            -RuntimeReleaseTag 'v0.12.4' -SourceCommit $sourceCommit `
            -OutputPath $first)
        [void](& $builderPath -SourceRoot $sourceRoot `
            -RuntimeReleaseTag 'v0.12.4' -SourceCommit $sourceCommit `
            -OutputPath $second)
        if ($PSVersionTable.PSEdition -ceq 'Desktop') {
            $windowsPowerShell = Join-Path $PSHOME 'powershell.exe'
            $previousPreference = $ErrorActionPreference
            try {
                $ErrorActionPreference = 'Continue'
                $defaultRootOutput = @(& $windowsPowerShell -NoProfile `
                    -ExecutionPolicy Bypass -File $fixtureBuilderPath `
                    -RuntimeReleaseTag 'v0.12.4' `
                    -SourceCommit $sourceCommit -OutputPath $defaultRoot 2>&1)
                $defaultRootExitCode = $LASTEXITCODE
            }
            finally { $ErrorActionPreference = $previousPreference }
            if ($defaultRootExitCode -ne 0) {
                throw "Windows PowerShell default-root build failed: $(@(
                    $defaultRootOutput
                ) -join [Environment]::NewLine)"
            }
        }
        else {
            [void](& $fixtureBuilderPath -RuntimeReleaseTag 'v0.12.4' `
                -SourceCommit $sourceCommit -OutputPath $defaultRoot)
        }
        if (-not (Test-Path -LiteralPath $first -PathType Leaf) -or
            -not (Test-Path -LiteralPath $second -PathType Leaf) -or
            -not (Test-Path -LiteralPath $defaultRoot -PathType Leaf)) {
            Add-Failure 'TEST-0147 deterministic builder did not create every bundle output.'
        }
        elseif ((Get-FileHash -LiteralPath $first -Algorithm SHA256).Hash -cne
                (Get-FileHash -LiteralPath $second -Algorithm SHA256).Hash -or
            (Get-FileHash -LiteralPath $first -Algorithm SHA256).Hash -cne
                (Get-FileHash -LiteralPath $defaultRoot -Algorithm SHA256).Hash) {
            Add-Failure 'TEST-0147 explicit and default source roots produced different bundle bytes.'
        }

        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [IO.Compression.ZipFile]::OpenRead($first)
        try {
            $entries = @($archive.Entries)
            $manifestEntry = @($entries | Where-Object {
                $_.FullName -ceq 'manifest.json'
            })
            if ($manifestEntry.Count -ne 1) {
                throw 'Production bundle does not contain one canonical manifest.'
            }
            $reader = [IO.StreamReader]::new(
                $manifestEntry[0].Open(), [Text.UTF8Encoding]::new($false, $true)
            )
            try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json }
            finally { $reader.Dispose() }
            if ([string]$manifest.sourceCommit -cne $sourceCommit -or
                [string]$manifest.runtimeReleaseTag -cne 'v0.12.4') {
                throw 'Production bundle manifest does not bind the exact source identity.'
            }
            $expectedEntryOrder = @('manifest.json') + @(
                $manifest.payload | ForEach-Object { [string]$_.path }
            )
            if ((@($entries | ForEach-Object { [string]$_.FullName }) -join "`n") -cne
                ($expectedEntryOrder -join "`n")) {
                throw 'Production bundle entry order differs from its canonical payload.'
            }
            foreach ($record in @($manifest.payload)) {
                $entry = @($entries | Where-Object {
                    $_.FullName -ceq [string]$record.path
                })
                if ($entry.Count -ne 1) {
                    throw "Production payload '$($record.path)' is missing or duplicated."
                }
                $sourceRelative = 'scripts/quick-adoption/' +
                    ([string]$record.path).Substring('MeAndAI.QuickAdoption/'.Length)
                $expectedBytes = Read-TestTrackedBlob -Repository $sourceRoot `
                    -Commit $sourceCommit -RelativePath $sourceRelative
                $stream = $entry[0].Open()
                $memory = [IO.MemoryStream]::new()
                try {
                    $stream.CopyTo($memory)
                    $actualBytes = $memory.ToArray()
                }
                finally {
                    $memory.Dispose()
                    $stream.Dispose()
                }
                if ((Get-FileDigest -Bytes $actualBytes) -cne
                    (Get-FileDigest -Bytes $expectedBytes)) {
                    throw "Production payload '$($record.path)' differs from its exact Git blob bytes."
                }
                if ($sourceRelative -ceq $transformRelativePath -and
                    (Get-FileDigest -Bytes $actualBytes) -ceq
                        (Get-FileDigest -Bytes $transformWorktreeBytes)) {
                    throw 'Production bundle used transformed working-tree bytes instead of the exact Git blob.'
                }
            }
        }
        finally { $archive.Dispose() }

        $extractionRoot = Join-Path $fixtureRoot 'production-runtime'
        [IO.Compression.ZipFile]::ExtractToDirectory($first, $extractionRoot)
        $productionModule = $null
        try {
            $productionModule = Import-Module -Name (Join-Path $extractionRoot `
                'MeAndAI.QuickAdoption/MeAndAI.QuickAdoption.psd1') -Force -PassThru
            $beforeStatus = @(& git -C $sourceRoot status --porcelain=v1)
            & (Get-Command Invoke-MeAndAIQuickAdoption -Module $productionModule.Name) `
                -TargetPath $sourceRoot -AdoptionStrategy Abort -NoProgress | Out-Null
            $afterStatus = @(& git -C $sourceRoot status --porcelain=v1)
            if (($beforeStatus -join "`n") -cne ($afterStatus -join "`n")) {
                throw 'Production bundle Abort path changed its source fixture.'
            }
        }
        finally {
            if ($null -ne $productionModule) {
                Remove-Module -ModuleInfo $productionModule -Force
            }
        }

        $partialOutput = Join-Path $fixtureRoot 'post-output-failure.zip'
        $global:MeAndAITestPartialOutputObserved = $false
        $postOutputFailureRejected = $false
        try {
            function global:Get-FileHash {
                param(
                    [Parameter(Mandatory)][string]$LiteralPath,
                    [string]$Algorithm
                )
                $item = Get-Item -LiteralPath $LiteralPath -Force `
                    -ErrorAction Stop
                $global:MeAndAITestPartialOutputObserved =
                    -not $item.PSIsContainer -and [long]$item.Length -gt 0
                throw 'injected post-output hash failure'
            }
            try {
                [void](& $builderPath -SourceRoot $sourceRoot `
                    -RuntimeReleaseTag 'v0.12.4' -SourceCommit $sourceCommit `
                    -OutputPath $partialOutput)
            }
            catch {
                $postOutputFailureRejected = $_.Exception.Message -like
                    '*injected post-output hash failure*'
            }
        }
        finally {
            Remove-Item Function:\global:Get-FileHash -ErrorAction SilentlyContinue
        }
        if (-not $postOutputFailureRejected -or
            -not [bool]$global:MeAndAITestPartialOutputObserved -or
            (Test-Path -LiteralPath $partialOutput)) {
            Add-Failure 'TEST-0147 builder did not remove an output created before a post-write failure.'
        }
        Remove-Variable MeAndAITestPartialOutputObserved -Scope Global `
            -ErrorAction SilentlyContinue

        $dirtySource = Join-Path $sourceRoot `
            'scripts/quick-adoption/Private/Configuration.ps1'
        [IO.File]::AppendAllText($dirtySource, "`n# dirty TEST-0147 source`n")
        $dirtyOutput = Join-Path $fixtureRoot 'dirty.zip'
        $dirtyRejected = $false
        try {
            [void](& $builderPath -SourceRoot $sourceRoot `
                -RuntimeReleaseTag 'v0.12.4' -SourceCommit $sourceCommit `
                -OutputPath $dirtyOutput)
        }
        catch {
            $dirtyRejected = $_.Exception.Message -like '*tracked*source*' -or
                $_.Exception.Message -like '*clean*'
        }
        if (-not $dirtyRejected -or (Test-Path -LiteralPath $dirtyOutput)) {
            Add-Failure 'TEST-0147 builder accepted dirty/self-asserted source bytes.'
        }
    }
    catch {
        Add-Failure "TEST-0147 deterministic bundle build failed: $($_.Exception.Message)"
    }
    finally {
        if (Test-Path -LiteralPath $fixtureRoot) {
            Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
        }
    }
}

$nativeHelperPath = Join-Path $root `
    'tests/capabilities/initial-adoption/fixtures/Invoke-MockQuickAdoptionRuntimeGh.ps1'
if (-not (Test-Path -LiteralPath $nativeHelperPath -PathType Leaf)) {
    Add-Failure 'TEST-0147 native runtime GitHub helper is missing.'
}
elseif ($bootstrap) {
    $runtimeRoot = Join-Path ([IO.Path]::GetTempPath()) `
        ('meandai-bootstrap-runtime-test-' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $runtimeRoot)
    $originalPath = [Environment]::GetEnvironmentVariable('PATH', 'Process')
    $originalGitHubHost = [Environment]::GetEnvironmentVariable('GH_HOST', 'Process')
    $originalGitHubToken = [Environment]::GetEnvironmentVariable('GH_TOKEN', 'Process')
    $originalTemp = [Environment]::GetEnvironmentVariable('TEMP', 'Process')
    $originalTmp = [Environment]::GetEnvironmentVariable('TMP', 'Process')
    $originalTmpDir = [Environment]::GetEnvironmentVariable('TMPDIR', 'Process')
    $testTempRoot = [IO.Path]::GetTempPath()
    $sourceCommit = 'a' * 40
    try {
        $fakeBin = Join-Path $runtimeRoot 'bin'
        [void](New-Item -ItemType Directory -Path $fakeBin)
        if ($env:OS -eq 'Windows_NT') {
            $wrapperPath = Join-Path $fakeBin 'gh.cmd'
            $wrapper = @"
@echo off
if "%~1"=="--version" (
  echo gh version 2.82.1
  exit /b 0
)
powershell -NoProfile -ExecutionPolicy Bypass -File "$nativeHelperPath" %*
exit /b %ERRORLEVEL%
"@ -replace "`n", "`r`n"
            [IO.File]::WriteAllText(
                $wrapperPath, $wrapper, [Text.ASCIIEncoding]::new()
            )
        }
        else {
            $wrapperPath = Join-Path $fakeBin 'gh'
            if ($nativeHelperPath.Contains("'")) {
                throw 'Native helper path cannot be represented safely by the fixture.'
            }
            $wrapper = "#!/bin/sh`nif [ `"`$1`" = `"--version`" ]; then`n  printf '%s\n' 'gh version 2.82.1'`n  exit 0`nfi`nexec pwsh -NoProfile -File '$nativeHelperPath' `"`$@`"`n"
            [IO.File]::WriteAllText(
                $wrapperPath, $wrapper, [Text.UTF8Encoding]::new($false)
            )
            & chmod +x $wrapperPath
            if ($LASTEXITCODE -ne 0) {
                throw 'Unable to make the fake gh wrapper executable.'
            }
        }
        [Environment]::SetEnvironmentVariable(
            'PATH', $fakeBin + [IO.Path]::PathSeparator + $originalPath, 'Process'
        )
        $validBundle = Join-Path $runtimeRoot 'valid.zip'
        $unsafeBundle = Join-Path $runtimeRoot 'unsafe.zip'
        $collisionBundle = Join-Path $runtimeRoot 'collision.zip'
        $wrongSourceBundle = Join-Path $runtimeRoot 'wrong-source.zip'
        $badPayloadBundle = Join-Path $runtimeRoot 'bad-payload.zip'
        New-TestRuntimeBundle -Path $validBundle -SourceCommit $sourceCommit
        New-TestRuntimeBundle -Path $unsafeBundle -SourceCommit $sourceCommit `
            -ExtraEntry '../escape.ps1'
        New-TestRuntimeBundle -Path $collisionBundle -SourceCommit $sourceCommit `
            -TrailingDotCollision
        New-TestRuntimeBundle -Path $wrongSourceBundle -SourceCommit $sourceCommit `
            -ManifestSourceCommit ('b' * 40)
        New-TestRuntimeBundle -Path $badPayloadBundle -SourceCommit $sourceCommit `
            -BadPayloadDigest

        [Environment]::SetEnvironmentVariable(
            'GH_HOST', 'hostile.example.invalid', 'Process'
        )
        [Environment]::SetEnvironmentVariable(
            'GH_TOKEN', 'preexisting-bootstrap-token', 'Process'
        )

        foreach ($scenario in @(
            [pscustomobject]@{
                Name = 'Valid'; Bundle = $validBundle; ShouldPass = $true
                Error = ''
            },
            [pscustomobject]@{
                Name = 'TokenFallback'; Bundle = $validBundle; ShouldPass = $true
                Error = ''
            },
            [pscustomobject]@{
                Name = 'MutableRelease'; Bundle = $validBundle; ShouldPass = $false
                Error = '*not one exact published immutable GitHub Release*'
            },
            [pscustomobject]@{
                Name = 'DuplicateAsset'; Bundle = $validBundle; ShouldPass = $false
                Error = '*exactly one*Bundle.zip*'
            },
            [pscustomobject]@{
                Name = 'BadDigest'; Bundle = $validBundle; ShouldPass = $false
                Error = '*does not match its immutable release digest*'
            },
            [pscustomobject]@{
                Name = 'UnsafeArchive'; Bundle = $unsafeBundle; ShouldPass = $false
                Error = '*unsafe or duplicated*'
            },
            [pscustomobject]@{
                Name = 'TrailingDotCollision'; Bundle = $collisionBundle
                ShouldPass = $false; Error = '*unsafe or duplicated*'
            },
            [pscustomobject]@{
                Name = 'OversizeAsset'; Bundle = $validBundle; ShouldPass = $false
                Error = '*exceeds*maximum*'
            },
            [pscustomobject]@{
                Name = 'WrongManifestSource'; Bundle = $wrongSourceBundle
                ShouldPass = $false; Error = '*manifest identity*'
            },
            [pscustomobject]@{
                Name = 'BadPayloadDigest'; Bundle = $badPayloadBundle
                ShouldPass = $false; Error = '*failed length or digest*'
            }
        )) {
            $sentinel = Join-Path $runtimeRoot ($scenario.Name + '.sentinel')
            $tokenPath = Join-Path $runtimeRoot 'MEANDAI_RO_FG_PAT.txt'
            if (Test-Path -LiteralPath $tokenPath) {
                Remove-Item -LiteralPath $tokenPath -Force
            }
            if ($scenario.Name -ceq 'TokenFallback') {
                [IO.File]::WriteAllText(
                    $tokenPath, 'test-read-token', [Text.UTF8Encoding]::new($false)
                )
            }
            $bundleBytes = [IO.File]::ReadAllBytes($scenario.Bundle)
            [Environment]::SetEnvironmentVariable(
                'MEANDAI_TEST_RUNTIME_MODE',
                $(if ($scenario.Name -cin @(
                    'UnsafeArchive', 'TrailingDotCollision',
                    'WrongManifestSource', 'BadPayloadDigest'
                )) {
                    'Valid'
                }
                elseif ($scenario.Name -ceq 'TokenFallback') { 'RequireToken' }
                else { $scenario.Name }),
                'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'MEANDAI_TEST_RUNTIME_BUNDLE', $scenario.Bundle, 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'MEANDAI_TEST_RUNTIME_DIGEST', (Get-FileDigest -Bytes $bundleBytes),
                'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'MEANDAI_TEST_RUNTIME_LENGTH', [string]$bundleBytes.LongLength,
                'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'MEANDAI_TEST_RUNTIME_COMMIT', $sourceCommit, 'Process'
            )
            [Environment]::SetEnvironmentVariable(
                'MEANDAI_TEST_RUNTIME_SENTINEL', $sentinel, 'Process'
            )
            $errorText = ''
            try {
                & (Join-Path $root $bootstrapRelativePath) `
                    -TargetPath $runtimeRoot | Out-Null
                if (-not $scenario.ShouldPass) {
                    Add-Failure "TEST-0147 invalid bootstrap scenario '$($scenario.Name)' succeeded."
                }
            }
            catch {
                $errorText = $_.Exception.Message
                if ($scenario.ShouldPass -or $errorText -notlike $scenario.Error) {
                    Add-Failure "TEST-0147 bootstrap scenario '$($scenario.Name)' failed unexpectedly: $errorText"
                }
            }
            if ($scenario.ShouldPass) {
                $expectedSentinel = "$runtimeRoot`nv0.12.4"
                if (-not (Test-Path -LiteralPath $sentinel -PathType Leaf) -or
                    [IO.File]::ReadAllText($sentinel) -cne $expectedSentinel) {
                    Add-Failure 'TEST-0147 verified thin bootstrap did not invoke its exact module entry point.'
                }
            }
            elseif (Test-Path -LiteralPath $sentinel) {
                Add-Failure "TEST-0147 invalid bootstrap scenario '$($scenario.Name)' executed module code."
            }
            if ([string]$env:GH_HOST -cne 'hostile.example.invalid' -or
                [string]$env:GH_TOKEN -cne 'preexisting-bootstrap-token') {
                Add-Failure "TEST-0147 bootstrap scenario '$($scenario.Name)' did not restore GitHub process environment."
            }
        }

        $consumerTemp = Join-Path $runtimeRoot 'consumer-temp'
        [void](New-Item -ItemType Directory -Path $consumerTemp)
        [Environment]::SetEnvironmentVariable('TEMP', $consumerTemp, 'Process')
        [Environment]::SetEnvironmentVariable('TMP', $consumerTemp, 'Process')
        [Environment]::SetEnvironmentVariable('TMPDIR', $consumerTemp, 'Process')
        $resolvedProcessTemp = [IO.Path]::GetFullPath(
            [IO.Path]::GetTempPath()
        ).TrimEnd([char[]]@(
            [IO.Path]::DirectorySeparatorChar,
            [IO.Path]::AltDirectorySeparatorChar
        ))
        $expectedProcessTemp = [IO.Path]::GetFullPath($consumerTemp).TrimEnd(
            [char[]]@(
                [IO.Path]::DirectorySeparatorChar,
                [IO.Path]::AltDirectorySeparatorChar
            )
        )
        $tempComparison = if ($env:OS -eq 'Windows_NT') {
            [StringComparison]::OrdinalIgnoreCase
        }
        else { [StringComparison]::Ordinal }
        if (-not $resolvedProcessTemp.Equals(
                $expectedProcessTemp, $tempComparison
            )) {
            throw 'The consumer-contained process-temp fixture did not activate.'
        }
        $tempSentinel = Join-Path $runtimeRoot 'UnsafeTempRoot.sentinel'
        [Environment]::SetEnvironmentVariable('MEANDAI_TEST_RUNTIME_MODE', 'Valid', 'Process')
        [Environment]::SetEnvironmentVariable('MEANDAI_TEST_RUNTIME_BUNDLE', $validBundle, 'Process')
        [Environment]::SetEnvironmentVariable('MEANDAI_TEST_RUNTIME_SENTINEL', $tempSentinel, 'Process')
        $tempRejected = $false
        try {
            & (Join-Path $root $bootstrapRelativePath) -TargetPath $runtimeRoot | Out-Null
        }
        catch { $tempRejected = $_.Exception.Message -like '*outside*consumer*' }
        finally {
            [Environment]::SetEnvironmentVariable('TEMP', $originalTemp, 'Process')
            [Environment]::SetEnvironmentVariable('TMP', $originalTmp, 'Process')
            [Environment]::SetEnvironmentVariable('TMPDIR', $originalTmpDir, 'Process')
        }
        if (-not $tempRejected -or (Test-Path -LiteralPath $tempSentinel)) {
            Add-Failure 'TEST-0147 bootstrap accepted a runtime temporary root inside the consumer.'
        }

        if ($env:OS -eq 'Windows_NT') {
            $realParent = Join-Path $runtimeRoot 'real-parent'
            $realConsumer = Join-Path $realParent 'consumer'
            $linkedParent = Join-Path $runtimeRoot 'linked-parent'
            [void](New-Item -ItemType Directory -Path $realConsumer -Force)
            [void](New-Item -ItemType Junction -Path $linkedParent -Target $realParent)
            [IO.File]::WriteAllText(
                (Join-Path $realConsumer 'MEANDAI_RO_FG_PAT.txt'),
                'test-read-token', [Text.UTF8Encoding]::new($false)
            )
            $junctionRejected = $false
            try {
                & (Join-Path $root $bootstrapRelativePath) `
                    -TargetPath (Join-Path $linkedParent 'consumer') | Out-Null
            }
            catch { $junctionRejected = $_.Exception.Message -like '*reparse*ancestor*' }
            if (-not $junctionRejected) {
                Add-Failure 'TEST-0147 bootstrap accepted a protocol token through a junction ancestor.'
            }
        }

        if (@(Get-ChildItem -LiteralPath $testTempRoot -Directory `
            -Filter 'meandai-quick-adoption-runtime-*' -ErrorAction SilentlyContinue).Count -ne 0) {
            Add-Failure 'TEST-0147 thin bootstrap left an owned runtime directory behind.'
        }
    }
    catch {
        Add-Failure "TEST-0147 native thin-bootstrap fixture failed: $($_.Exception.Message)"
    }
    finally {
        [Environment]::SetEnvironmentVariable('PATH', $originalPath, 'Process')
        [Environment]::SetEnvironmentVariable('GH_HOST', $originalGitHubHost, 'Process')
        [Environment]::SetEnvironmentVariable('GH_TOKEN', $originalGitHubToken, 'Process')
        [Environment]::SetEnvironmentVariable('TEMP', $originalTemp, 'Process')
        [Environment]::SetEnvironmentVariable('TMP', $originalTmp, 'Process')
        [Environment]::SetEnvironmentVariable('TMPDIR', $originalTmpDir, 'Process')
        foreach ($name in @(
            'MEANDAI_TEST_RUNTIME_MODE', 'MEANDAI_TEST_RUNTIME_BUNDLE',
            'MEANDAI_TEST_RUNTIME_DIGEST', 'MEANDAI_TEST_RUNTIME_LENGTH',
            'MEANDAI_TEST_RUNTIME_COMMIT', 'MEANDAI_TEST_RUNTIME_SENTINEL'
        )) {
            [Environment]::SetEnvironmentVariable($name, $null, 'Process')
        }
        if (Test-Path -LiteralPath $runtimeRoot) {
            Remove-Item -LiteralPath $runtimeRoot -Recurse -Force
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host 'Quick-adoption bundle tests failed:' -ForegroundColor Red
    foreach ($failure in $failures) { Write-Host " - $failure" -ForegroundColor Red }
    exit 1
}

Confirm-MeAndAIScenarioEvidence -TestId 'TEST-0147'
$scenarioResult = New-MeAndAIScenarioResult -Owner $owner `
    -SourcePaths @($PSCommandPath) -AuthorityPath $scenarioAuthorityPath
Write-Output ('MEANDAI_SCENARIO_RESULTS=' + `
    ($scenarioResult | ConvertTo-Json -Compress))
