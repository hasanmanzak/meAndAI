Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'MeAndAI.ContentIdentity.psm1') `
    -Force -ErrorAction Stop

$script:LedgerPath = '.ai/meandai-update-state.json'

function Assert-ExactProperties {
    param(
        [Parameter(Mandatory)]$Value,
        [Parameter(Mandatory)][string[]]$Expected,
        [Parameter(Mandatory)][string]$Label
    )

    if ($null -eq $Value) {
        throw "$Label is null."
    }
    $actual = @($Value.PSObject.Properties | ForEach-Object { [string]$_.Name })
    if ($actual.Count -ne $Expected.Count) {
        throw "$Label has an unsupported property set."
    }
    foreach ($name in $Expected) {
        if ($actual -cnotcontains $name) {
            throw "$Label is missing required property '$name'."
        }
    }
}

function ConvertFrom-StrictUtf8Bytes {
    param(
        [Parameter(Mandatory)][byte[]]$Bytes,
        [Parameter(Mandatory)][string]$Label,
        [switch]$AllowBom
    )

    $hasBom = $Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and
        $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF
    if ($hasBom -and -not $AllowBom) {
        throw "$Label must be UTF-8 without a byte-order mark."
    }
    $offset = if ($hasBom) { 3 } else { 0 }
    try {
        $text = [Text.UTF8Encoding]::new($false, $true).GetString(
            $Bytes, $offset, $Bytes.Length - $offset
        )
    }
    catch {
        throw "$Label is not strict UTF-8."
    }
    return [pscustomobject]@{ Text = $text; HasBom = $hasBom }
}

function ConvertTo-VersionRecord {
    param([Parameter(Mandatory)][string]$Tag)

    if ($Tag -cnotmatch '^v(?<major>0|[1-9][0-9]*)\.(?<minor>0|[1-9][0-9]*)\.(?<revision>0|[1-9][0-9]*)$') {
        throw "Migration version '$Tag' is not canonical vM.m.rev."
    }
    return [pscustomobject]@{
        Tag = $Tag
        Major = [Numerics.BigInteger]::Parse($Matches.major, [Globalization.CultureInfo]::InvariantCulture)
        Minor = [Numerics.BigInteger]::Parse($Matches.minor, [Globalization.CultureInfo]::InvariantCulture)
        Revision = [Numerics.BigInteger]::Parse($Matches.revision, [Globalization.CultureInfo]::InvariantCulture)
    }
}

function Compare-VersionRecord {
    param([Parameter(Mandatory)]$Left, [Parameter(Mandatory)]$Right)

    foreach ($name in @('Major', 'Minor', 'Revision')) {
        $comparison = $Left.$name.CompareTo($Right.$name)
        if ($comparison -ne 0) {
            return $comparison
        }
    }
    return 0
}

function Assert-CanonicalRelativePath {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)

    if ([string]::IsNullOrWhiteSpace($Path) -or
        $Path -cnotmatch '^[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*$' -or
        @($Path.Split('/')) -contains '..' -or @($Path.Split('/')) -contains '.') {
        throw "$Label path '$Path' is not a canonical repository-relative path."
    }
}

function ConvertFrom-JsonBytes {
    param([Parameter(Mandatory)][byte[]]$Bytes, [Parameter(Mandatory)][string]$Label)

    $decoded = ConvertFrom-StrictUtf8Bytes -Bytes $Bytes -Label $Label
    if ($decoded.Text.Contains("`r")) {
        throw "$Label must use LF line endings."
    }
    try {
        return $decoded.Text | ConvertFrom-Json
    }
    catch {
        throw "$Label is not valid JSON: $($_.Exception.Message)"
    }
}

function ConvertFrom-LineArray {
    param($Value, [Parameter(Mandatory)][string]$Label)

    if ($Value -isnot [Array] -or @($Value).Count -eq 0) {
        throw "$Label must be a non-empty JSON string array."
    }
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in @($Value)) {
        if ($line -isnot [string] -or ([string]$line).Contains("`r") -or
            ([string]$line).Contains("`n")) {
            throw "$Label contains a non-string value or an embedded line ending."
        }
        $lines.Add([string]$line)
    }
    return $lines -join "`n"
}

function Import-MeAndAIConsumerMigrationCatalog {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$IndexPath)

    $fullIndexPath = [IO.Path]::GetFullPath($IndexPath)
    if (-not (Test-Path -LiteralPath $fullIndexPath -PathType Leaf)) {
        throw "Migration catalog index does not exist: $fullIndexPath"
    }
    $indexBytes = [IO.File]::ReadAllBytes($fullIndexPath)
    $index = ConvertFrom-JsonBytes -Bytes $indexBytes -Label 'Migration catalog index'
    Assert-ExactProperties -Value $index -Expected @('schema', 'migrations') `
        -Label 'Migration catalog index'
    if (($index.schema -isnot [int] -and $index.schema -isnot [long]) -or
        [long]$index.schema -ne 1 -or
        $index.migrations -isnot [Array]) {
        throw 'Migration catalog index has an unsupported schema or migration collection.'
    }

    $root = [IO.Path]::GetDirectoryName($fullIndexPath)
    $seenIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $seenFiles = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $migrations = [System.Collections.Generic.List[object]]::new()
    $previousVersion = $null
    $previousId = ''

    foreach ($entry in @($index.migrations)) {
        Assert-ExactProperties -Value $entry `
            -Expected @('id', 'introducedIn', 'definition') `
            -Label 'Migration catalog entry'
        $id = [string]$entry.id
        $introducedIn = [string]$entry.introducedIn
        $definitionName = [string]$entry.definition
        if ($id -cnotmatch '^MIG-[0-9]{4}$' -or -not $seenIds.Add($id)) {
            throw "Migration catalog ID '$id' is invalid or duplicated."
        }
        if ($definitionName -cne "$id.json" -or -not $seenFiles.Add($definitionName)) {
            throw "Migration definition '$definitionName' is not the exact unique file for '$id'."
        }
        Assert-CanonicalRelativePath -Path $definitionName -Label 'Migration definition'
        $version = ConvertTo-VersionRecord -Tag $introducedIn
        if ($null -ne $previousVersion) {
            $versionOrder = Compare-VersionRecord -Left $version -Right $previousVersion
            if ($versionOrder -lt 0 -or ($versionOrder -eq 0 -and
                [string]::CompareOrdinal($id, $previousId) -le 0)) {
                throw 'Migration catalog entries are not in canonical version and ID order.'
            }
        }

        $definitionPath = [IO.Path]::GetFullPath((Join-Path $root $definitionName))
        if (-not ([IO.Path]::GetDirectoryName($definitionPath)).Equals(
            $root, [StringComparison]::OrdinalIgnoreCase
        ) -or -not (Test-Path -LiteralPath $definitionPath -PathType Leaf)) {
            throw "Migration definition '$definitionName' is absent or escapes the catalog root."
        }
        $definitionBytes = [IO.File]::ReadAllBytes($definitionPath)
        $definition = ConvertFrom-JsonBytes -Bytes $definitionBytes `
            -Label "Migration definition '$id'"
        Assert-ExactProperties -Value $definition -Expected @('schema', 'id', 'operations') `
            -Label "Migration definition '$id'"
        if (($definition.schema -isnot [int] -and $definition.schema -isnot [long]) -or
            [long]$definition.schema -ne 1 -or
            [string]$definition.id -cne $id -or $definition.operations -isnot [Array] -or
            @($definition.operations).Count -eq 0) {
            throw "Migration definition '$id' has an unsupported schema, identity, or operation collection."
        }

        $seenPaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $operations = [System.Collections.Generic.List[object]]::new()
        foreach ($operation in @($definition.operations)) {
            Assert-ExactProperties -Value $operation `
                -Expected @('kind', 'path', 'before', 'after') `
                -Label "Migration '$id' operation"
            $path = [string]$operation.path
            if ([string]$operation.kind -cne 'replace-exactly-once') {
                throw "Migration '$id' uses unsupported operation '$($operation.kind)'."
            }
            Assert-CanonicalRelativePath -Path $path -Label "Migration '$id' operation"
            if (-not $seenPaths.Add($path) -or $path -ceq $script:LedgerPath) {
                throw "Migration '$id' path '$path' is duplicated or reserved."
            }
            $before = ConvertFrom-LineArray -Value $operation.before `
                -Label "Migration '$id' path '$path' before"
            $after = ConvertFrom-LineArray -Value $operation.after `
                -Label "Migration '$id' path '$path' after"
            if ($before.Length -eq 0 -or $after.Length -eq 0 -or $before -ceq $after -or
                $before.Contains($after) -or $after.Contains($before)) {
                throw "Migration '$id' path '$path' has empty, equal, or overlapping fragments."
            }
            $operations.Add([pscustomobject]@{
                Kind = 'replace-exactly-once'
                Path = $path
                Before = $before
                After = $after
            })
        }

        $migrations.Add([pscustomobject]@{
            Id = $id
            IntroducedIn = $introducedIn
            Definition = $definitionName
            DefinitionBlob = Get-MeAndAIGitBlobSha1 -Bytes $definitionBytes
            Operations = @($operations)
        })
        $previousVersion = $version
        $previousId = $id
    }

    $catalog = [pscustomobject]@{
        Schema = 1
        IndexPath = $fullIndexPath
        IndexBlob = Get-MeAndAIGitBlobSha1 -Bytes $indexBytes
        Migrations = @($migrations)
    }
    $catalog.PSObject.TypeNames.Insert(0, 'MeAndAI.ConsumerMigrationCatalog')
    return $catalog
}

function New-LedgerEntry {
    param([Parameter(Mandatory)]$Migration)

    return [pscustomobject]@{
        Id = [string]$Migration.Id
        DefinitionBlob = [string]$Migration.DefinitionBlob
    }
}

function ConvertTo-LedgerBytes {
    param([AllowEmptyCollection()][object[]]$Entries)

    $items = @($Entries | ForEach-Object {
        '{"id":"' + [string]$_.Id + '","definitionBlob":"' +
            [string]$_.DefinitionBlob + '"}'
    })
    $text = '{"schema":1,"satisfied":[' + ($items -join ',') + "]}`n"
    return ,([Text.UTF8Encoding]::new($false).GetBytes($text))
}

function ConvertFrom-LedgerBytes {
    param([AllowNull()][byte[]]$Bytes)

    if ($null -eq $Bytes) {
        return [pscustomobject]@{ Missing = $true; Entries = @(); Bytes = $null }
    }
    $ledger = ConvertFrom-JsonBytes -Bytes $Bytes -Label 'Consumer migration ledger'
    Assert-ExactProperties -Value $ledger -Expected @('schema', 'satisfied') `
        -Label 'Consumer migration ledger'
    if (($ledger.schema -isnot [int] -and $ledger.schema -isnot [long]) -or
        [long]$ledger.schema -ne 1 -or
        $ledger.satisfied -isnot [Array]) {
        throw 'Consumer migration ledger has an unsupported schema or satisfied collection.'
    }
    $entries = [System.Collections.Generic.List[object]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($entry in @($ledger.satisfied)) {
        Assert-ExactProperties -Value $entry -Expected @('id', 'definitionBlob') `
            -Label 'Consumer migration ledger entry'
        $id = [string]$entry.id
        $blob = [string]$entry.definitionBlob
        if ($id -cnotmatch '^MIG-[0-9]{4}$' -or -not $seen.Add($id) -or
            $blob -cnotmatch '^[0-9a-f]{40}$') {
            throw "Consumer migration ledger entry '$id' is invalid or duplicated."
        }
        $entries.Add([pscustomobject]@{ Id = $id; DefinitionBlob = $blob })
    }
    $canonicalBytes = ConvertTo-LedgerBytes -Entries @($entries)
    if (-not (Test-MeAndAIByteArrayEqual -Left $Bytes -Right $canonicalBytes)) {
        throw 'Consumer migration ledger is not in canonical UTF-8 JSON form.'
    }
    return [pscustomobject]@{ Missing = $false; Entries = @($entries); Bytes = $Bytes }
}

function New-MeAndAIConsumerMigrationBaseline {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Catalog)

    Assert-CatalogObject -Catalog $Catalog
    $entries = @($Catalog.Migrations | ForEach-Object { New-LedgerEntry -Migration $_ })
    $bytes = ConvertTo-LedgerBytes -Entries $entries
    return [pscustomobject]@{
        Path = $script:LedgerPath
        Entries = $entries
        Bytes = $bytes
        Blob = Get-MeAndAIGitBlobSha1 -Bytes $bytes
    }
}

function Assert-CatalogObject {
    param([Parameter(Mandatory)]$Catalog)

    if ($Catalog.PSObject.TypeNames -cnotcontains 'MeAndAI.ConsumerMigrationCatalog' -or
        [int]$Catalog.Schema -ne 1 -or $Catalog.Migrations -isnot [Array]) {
        throw 'Catalog must be produced by Import-MeAndAIConsumerMigrationCatalog.'
    }
}

function Get-ValidatedLedgerPrefix {
    param(
        [Parameter(Mandatory)]$Catalog,
        [AllowNull()][byte[]]$LedgerBytes
    )

    Assert-CatalogObject -Catalog $Catalog
    $ledger = ConvertFrom-LedgerBytes -Bytes $LedgerBytes
    if ($ledger.Entries.Count -gt $Catalog.Migrations.Count) {
        throw 'Consumer migration ledger is longer than the installed catalog.'
    }
    for ($index = 0; $index -lt $ledger.Entries.Count; $index++) {
        $actual = $ledger.Entries[$index]
        $expected = $Catalog.Migrations[$index]
        if ([string]$actual.Id -cne [string]$expected.Id -or
            [string]$actual.DefinitionBlob -cne [string]$expected.DefinitionBlob) {
            throw 'Consumer migration ledger is not the exact installed-catalog prefix.'
        }
    }
    return $ledger
}

function Get-MeAndAIConsumerMigrationRequiredPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Catalog,
        [AllowNull()][byte[]]$LedgerBytes = $null
    )

    $ledger = Get-ValidatedLedgerPrefix -Catalog $Catalog -LedgerBytes $LedgerBytes
    $paths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($migration in @($Catalog.Migrations | Select-Object -Skip $ledger.Entries.Count)) {
        foreach ($operation in @($migration.Operations)) {
            [void]$paths.Add([string]$operation.Path)
        }
    }
    return @(Get-OrdinalSortedStrings -Values @($paths))
}

function Assert-MeAndAIConsumerMigrationCatalogExtension {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$CurrentCatalog,
        [Parameter(Mandatory)]$TargetCatalog
    )

    Assert-CatalogObject -Catalog $CurrentCatalog
    Assert-CatalogObject -Catalog $TargetCatalog
    if ($TargetCatalog.Migrations.Count -lt $CurrentCatalog.Migrations.Count) {
        throw 'Target migration catalog removes installed migration definitions.'
    }
    for ($index = 0; $index -lt $CurrentCatalog.Migrations.Count; $index++) {
        $current = $CurrentCatalog.Migrations[$index]
        $target = $TargetCatalog.Migrations[$index]
        if ([string]$target.Id -cne [string]$current.Id -or
            [string]$target.IntroducedIn -cne [string]$current.IntroducedIn -or
            [string]$target.Definition -cne [string]$current.Definition -or
            [string]$target.DefinitionBlob -cne [string]$current.DefinitionBlob) {
            throw "Target migration catalog changes installed prefix entry '$($current.Id)'."
        }
    }
}

function Assert-MeAndAIConsumerMigrationCatalogChain {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object[]]$Catalogs)

    if (@($Catalogs).Count -eq 0) {
        throw 'Consumer migration catalog chain must contain at least one catalog.'
    }
    foreach ($catalog in @($Catalogs)) {
        Assert-CatalogObject -Catalog $catalog
    }
    for ($index = 1; $index -lt @($Catalogs).Count; $index++) {
        Assert-MeAndAIConsumerMigrationCatalogExtension `
            -CurrentCatalog $Catalogs[$index - 1] `
            -TargetCatalog $Catalogs[$index]
    }
}

function Get-OrdinalOccurrenceCount {
    param([Parameter(Mandatory)][string]$Text, [Parameter(Mandatory)][string]$Value)

    $count = 0
    $offset = 0
    while ($offset -le ($Text.Length - $Value.Length)) {
        $index = $Text.IndexOf($Value, $offset, [StringComparison]::Ordinal)
        if ($index -lt 0) { break }
        $count++
        $offset = $index + $Value.Length
    }
    return $count
}

function ConvertFrom-ConsumerFileBytes {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][byte[]]$Bytes
    )

    $decoded = ConvertFrom-StrictUtf8Bytes -Bytes $Bytes `
        -Label "Migration input '$Path'" -AllowBom
    $withoutCrLf = $decoded.Text.Replace("`r`n", '')
    if ($withoutCrLf.Contains("`r") -or
        ($decoded.Text.Contains("`r`n") -and $withoutCrLf.Contains("`n"))) {
        throw "Migration input '$Path' has unsupported or mixed line endings."
    }
    return [pscustomobject]@{
        Path = $Path
        OriginalBytes = $Bytes
        HasBom = [bool]$decoded.HasBom
        NewLine = if ($decoded.Text.Contains("`r`n")) { "`r`n" } else { "`n" }
        Text = $decoded.Text.Replace("`r`n", "`n")
    }
}

function ConvertTo-ConsumerFileBytes {
    param([Parameter(Mandatory)]$File)

    $text = if ([string]$File.NewLine -ceq "`r`n") {
        ([string]$File.Text).Replace("`n", "`r`n")
    }
    else { [string]$File.Text }
    $body = [Text.UTF8Encoding]::new($false).GetBytes($text)
    if (-not [bool]$File.HasBom) {
        return ,$body
    }
    $result = [byte[]]::new($body.Length + 3)
    $result[0] = 0xEF; $result[1] = 0xBB; $result[2] = 0xBF
    [Array]::Copy($body, 0, $result, 3, $body.Length)
    return ,$result
}

function Get-OrdinalSortedStrings {
    param([AllowEmptyCollection()][string[]]$Values)

    $result = [string[]]@($Values)
    [Array]::Sort($result, [StringComparer]::Ordinal)
    return $result
}

function Resolve-MeAndAIConsumerMigrationPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Catalog,
        [AllowEmptyCollection()][object[]]$Files = @(),
        [AllowNull()][byte[]]$LedgerBytes = $null
    )

    $ledger = Get-ValidatedLedgerPrefix -Catalog $Catalog -LedgerBytes $LedgerBytes

    $pending = @($Catalog.Migrations | Select-Object -Skip $ledger.Entries.Count)
    $requiredPaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($migration in $pending) {
        foreach ($operation in @($migration.Operations)) {
            [void]$requiredPaths.Add([string]$operation.Path)
        }
    }

    $fileMap = [System.Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
    foreach ($record in @($Files)) {
        Assert-ExactProperties -Value $record -Expected @('Path', 'Bytes') `
            -Label 'Migration input file record'
        $path = [string]$record.Path
        Assert-CanonicalRelativePath -Path $path -Label 'Migration input file'
        if ($record.Bytes -isnot [byte[]] -or -not $requiredPaths.Contains($path) -or
            $fileMap.ContainsKey($path)) {
            throw "Migration input file '$path' is unexpected, duplicated, or not a byte array."
        }
        $fileMap.Add($path, (ConvertFrom-ConsumerFileBytes -Path $path `
            -Bytes ([byte[]]$record.Bytes)))
    }
    if ($fileMap.Count -ne $requiredPaths.Count) {
        $missing = @($requiredPaths | Where-Object { -not $fileMap.ContainsKey($_) })
        throw "Migration input files do not match the exact pending path set; missing: $($missing -join ', ')."
    }

    $resultEntries = [System.Collections.Generic.List[object]]::new()
    foreach ($entry in @($ledger.Entries)) {
        $resultEntries.Add([pscustomobject]@{
            Id = [string]$entry.Id
            DefinitionBlob = [string]$entry.DefinitionBlob
        })
    }
    $migrationEvidence = [System.Collections.Generic.List[object]]::new()
    foreach ($migration in $pending) {
        $operationStates = [System.Collections.Generic.List[string]]::new()
        foreach ($operation in @($migration.Operations)) {
            $file = $fileMap[[string]$operation.Path]
            $beforeCount = Get-OrdinalOccurrenceCount -Text ([string]$file.Text) `
                -Value ([string]$operation.Before)
            $afterCount = Get-OrdinalOccurrenceCount -Text ([string]$file.Text) `
                -Value ([string]$operation.After)
            if ($beforeCount -eq 1 -and $afterCount -eq 0) {
                $operationStates.Add('Before')
            }
            elseif ($beforeCount -eq 0 -and $afterCount -eq 1) {
                $operationStates.Add('After')
            }
            else {
                throw "Migration '$($migration.Id)' path '$($operation.Path)' is unsupported: before=$beforeCount after=$afterCount."
            }
        }
        $beforeStates = @($operationStates | Where-Object { $_ -ceq 'Before' })
        $afterStates = @($operationStates | Where-Object { $_ -ceq 'After' })
        if ($beforeStates.Count -eq $operationStates.Count) {
            $migrationState = 'Applied'
            foreach ($operation in @($migration.Operations)) {
                $file = $fileMap[[string]$operation.Path]
                $file.Text = ([string]$file.Text).Replace(
                    [string]$operation.Before, [string]$operation.After
                )
            }
        }
        elseif ($afterStates.Count -eq $operationStates.Count) {
            $migrationState = 'AlreadySatisfied'
        }
        else {
            throw "Migration '$($migration.Id)' is partial; all operations must be exactly before or exactly after."
        }
        $resultEntries.Add((New-LedgerEntry -Migration $migration))
        $migrationEvidence.Add([pscustomobject]@{
            Id = [string]$migration.Id
            DefinitionBlob = [string]$migration.DefinitionBlob
            State = $migrationState
        })
    }

    $pathEvidence = [System.Collections.Generic.List[object]]::new()
    foreach ($path in @(Get-OrdinalSortedStrings -Values @($requiredPaths))) {
        $file = $fileMap[$path]
        $resultBytes = ConvertTo-ConsumerFileBytes -File $file
        $pathEvidence.Add([pscustomobject]@{
            Path = $path
            OriginalBlob = Get-MeAndAIGitBlobSha1 -Bytes ([byte[]]$file.OriginalBytes)
            OriginalBytes = [byte[]]$file.OriginalBytes
            ResultBlob = Get-MeAndAIGitBlobSha1 -Bytes $resultBytes
            Changed = -not (Test-MeAndAIByteArrayEqual -Left ([byte[]]$file.OriginalBytes) `
                -Right $resultBytes)
            ResultBytes = $resultBytes
        })
    }

    $resultLedgerBytes = ConvertTo-LedgerBytes -Entries @($resultEntries)
    $ledgerChanged = $ledger.Missing -or
        -not (Test-MeAndAIByteArrayEqual -Left $LedgerBytes -Right $resultLedgerBytes)
    $ledgerEvidence = [pscustomobject]@{
        Path = $script:LedgerPath
        OriginalBlob = if ($ledger.Missing) { '' } else { Get-MeAndAIGitBlobSha1 -Bytes $LedgerBytes }
        OriginalBytes = if ($ledger.Missing) { $null } else { [byte[]]$LedgerBytes }
        ResultBlob = Get-MeAndAIGitBlobSha1 -Bytes $resultLedgerBytes
        Changed = $ledgerChanged
        ResultBytes = $resultLedgerBytes
    }

    $changedPaths = [System.Collections.Generic.List[string]]::new()
    foreach ($pathResult in @($pathEvidence)) {
        if ([bool]$pathResult.Changed) { $changedPaths.Add([string]$pathResult.Path) }
    }
    if ($ledgerChanged) { $changedPaths.Add($script:LedgerPath) }
    $expectedChangedPaths = @(Get-OrdinalSortedStrings -Values @($changedPaths))

    $evidenceLines = [System.Collections.Generic.List[string]]::new()
    $evidenceLines.Add('schema=1')
    $evidenceLines.Add("catalog=$($Catalog.IndexBlob)")
    foreach ($migrationResult in @($migrationEvidence)) {
        $evidenceLines.Add(
            "migration=$($migrationResult.Id)|$($migrationResult.DefinitionBlob)|$($migrationResult.State)"
        )
    }
    foreach ($pathResult in @($pathEvidence)) {
        $evidenceLines.Add(
            "path=$($pathResult.Path)|$($pathResult.OriginalBlob)|$($pathResult.ResultBlob)|$([int][bool]$pathResult.Changed)"
        )
    }
    $evidenceLines.Add(
        "ledger=$($ledgerEvidence.OriginalBlob)|$($ledgerEvidence.ResultBlob)|$([int][bool]$ledgerEvidence.Changed)"
    )
    $planBytes = [Text.UTF8Encoding]::new($false).GetBytes(
        ($evidenceLines -join "`n") + "`n"
    )

    return [pscustomobject]@{
        Schema = 1
        State = if ($expectedChangedPaths.Count -eq 0) { 'Satisfied' } else { 'ChangesRequired' }
        LedgerWasMissing = [bool]$ledger.Missing
        Migrations = @($migrationEvidence)
        Paths = @($pathEvidence)
        Ledger = $ledgerEvidence
        ExpectedChangedPaths = $expectedChangedPaths
        PlanSha256 = Get-MeAndAISha256 -Bytes $planBytes
        PlanEvidenceBytes = $planBytes
    }
}

Export-ModuleMember -Function @(
    'Import-MeAndAIConsumerMigrationCatalog',
    'New-MeAndAIConsumerMigrationBaseline',
    'Get-MeAndAIConsumerMigrationRequiredPaths',
    'Assert-MeAndAIConsumerMigrationCatalogExtension',
    'Assert-MeAndAIConsumerMigrationCatalogChain',
    'Resolve-MeAndAIConsumerMigrationPlan'
)
