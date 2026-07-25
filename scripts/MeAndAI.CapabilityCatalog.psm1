Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'MeAndAI.ContentIdentity.psm1') `
    -Force -ErrorAction Stop

$script:LedgerPath = '.ai/meandai-capabilities-state.json'
$script:ReviewedAtFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
$script:CapabilityTypes = @(
    'Deterministic',
    'DeclarativeMigration',
    'Semantic',
    'Manual'
)
$script:TerminalOutcomes = @('Conforming', 'NotApplicable')
$script:EvidenceKinds = @{
    Deterministic = 'DeterministicEvidence'
    DeclarativeMigration = 'MigrationLedger'
    Semantic = 'SemanticReview'
    Manual = 'ManualEvidence'
}

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
        [Parameter(Mandatory)][string]$Label
    )

    $hasBom = $Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and
        $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF
    if ($hasBom) {
        throw "$Label must be UTF-8 without a byte-order mark."
    }
    try {
        $text = [Text.UTF8Encoding]::new($false, $true).GetString($Bytes)
    }
    catch {
        throw "$Label is not strict UTF-8."
    }
    if ($text.Contains("`r")) {
        throw "$Label must use LF line endings."
    }
    return $text
}

function ConvertFrom-JsonBytes {
    param(
        [Parameter(Mandatory)][byte[]]$Bytes,
        [Parameter(Mandatory)][string]$Label
    )

    $text = ConvertFrom-StrictUtf8Bytes -Bytes $Bytes -Label $Label
    try {
        return $text | ConvertFrom-Json
    }
    catch {
        throw "$Label is not valid JSON: $($_.Exception.Message)"
    }
}

function Assert-OrdinaryLeaf {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Label does not exist: $Path"
    }
    $attributes = [IO.File]::GetAttributes($Path)
    if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "$Label must not be a link or reparse point."
    }
}

function Test-CanonicalSlug {
    param([AllowNull()][string]$Value)
    return -not [string]::IsNullOrWhiteSpace($Value) -and
        $Value -cmatch '^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$'
}

function Assert-MeaningfulLine {
    param(
        [AllowNull()][string]$Value,
        [Parameter(Mandatory)][string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.Length -gt 4096 -or
        $Value.Contains("`r") -or $Value.Contains("`n") -or
        $Value -cne $Value.Trim()) {
        throw "$Label must be one non-empty trimmed line."
    }
}

function Get-ValidatedStringArray {
    param(
        [AllowNull()]$Value,
        [Parameter(Mandatory)][string]$Label,
        [switch]$AllowEmpty,
        [switch]$RequireOrdinalOrder
    )

    if ($Value -isnot [Array]) {
        throw "$Label must be a JSON string array."
    }
    $values = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($item in @($Value)) {
        if ($item -isnot [string]) {
            throw "$Label contains a non-string value."
        }
        $text = [string]$item
        Assert-MeaningfulLine -Value $text -Label $Label
        if (-not $seen.Add($text)) {
            throw "$Label contains duplicate evidence."
        }
        $values.Add($text)
    }
    if (-not $AllowEmpty -and $values.Count -eq 0) {
        throw "$Label must contain at least one value."
    }
    if ($RequireOrdinalOrder) {
        $sorted = [string[]]@($values)
        [Array]::Sort($sorted, [StringComparer]::Ordinal)
        for ($index = 0; $index -lt $sorted.Count; $index++) {
            if ([string]$values[$index] -cne [string]$sorted[$index]) {
                throw "$Label must be in ordinal order."
            }
        }
    }
    return @($values)
}

function Assert-CapabilityDefinition {
    param(
        [Parameter(Mandatory)]$Definition,
        [Parameter(Mandatory)][string]$Slug,
        [Parameter(Mandatory)][string]$Type
    )

    Assert-ExactProperties -Value $Definition -Expected @(
        'schema', 'slug', 'type', 'title', 'applicability', 'requirements', 'evidence'
    ) -Label "Capability definition '$Slug'"
    if (($Definition.schema -isnot [int] -and $Definition.schema -isnot [long]) -or
        [long]$Definition.schema -ne 1 -or [string]$Definition.slug -cne $Slug -or
        [string]$Definition.type -cne $Type) {
        throw "Capability definition '$Slug' identity or type does not match its catalog entry."
    }
    Assert-MeaningfulLine -Value ([string]$Definition.title) `
        -Label "Capability definition '$Slug' title"

    Assert-ExactProperties -Value $Definition.applicability `
        -Expected @('condition', 'description') `
        -Label "Capability definition '$Slug' applicability"
    $condition = [string]$Definition.applicability.condition
    if (-not (Test-CanonicalSlug -Value $condition)) {
        throw "Capability definition '$Slug' applicability condition is invalid."
    }
    Assert-MeaningfulLine -Value ([string]$Definition.applicability.description) `
        -Label "Capability definition '$Slug' applicability description"

    if ($Definition.requirements -isnot [Array] -or
        @($Definition.requirements).Count -eq 0) {
        throw "Capability definition '$Slug' must declare at least one requirement."
    }
    $seenRequirements = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($requirement in @($Definition.requirements)) {
        Assert-ExactProperties -Value $requirement -Expected @('id', 'statement') `
            -Label "Capability definition '$Slug' requirement"
        $requirementId = [string]$requirement.id
        if (-not (Test-CanonicalSlug -Value $requirementId) -or
            -not $seenRequirements.Add($requirementId)) {
            throw "Capability definition '$Slug' requirement ID '$requirementId' is invalid or duplicated."
        }
        Assert-MeaningfulLine -Value ([string]$requirement.statement) `
            -Label "Capability definition '$Slug' requirement '$requirementId' statement"
    }

    Assert-ExactProperties -Value $Definition.evidence `
        -Expected @('conforming', 'notApplicable') `
        -Label "Capability definition '$Slug' evidence"
    [void](Get-ValidatedStringArray -Value $Definition.evidence.conforming `
        -Label "Capability definition '$Slug' conforming evidence")
    [void](Get-ValidatedStringArray -Value $Definition.evidence.notApplicable `
        -Label "Capability definition '$Slug' not-applicable evidence")
}

function Assert-CatalogObject {
    param([Parameter(Mandatory)]$Catalog)

    if ($Catalog.PSObject.TypeNames -cnotcontains 'MeAndAI.CapabilityCatalog' -or
        [int]$Catalog.Schema -ne 1 -or $Catalog.Capabilities -isnot [Array] -or
        [string]$Catalog.CatalogDigest -cnotmatch '^[0-9a-f]{64}$') {
        throw 'Catalog must be produced by Import-MeAndAICapabilityCatalog.'
    }
}

function Assert-CapabilityObject {
    param([Parameter(Mandatory)]$Capability)

    if ($Capability.PSObject.TypeNames -cnotcontains 'MeAndAI.CapabilityDefinition' -or
        -not (Test-CanonicalSlug -Value ([string]$Capability.Slug)) -or
        $script:CapabilityTypes -cnotcontains [string]$Capability.Type -or
        [string]$Capability.DefinitionBlob -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Capability must be produced by Import-MeAndAICapabilityCatalog.'
    }
}

function Import-MeAndAICapabilityCatalog {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$IndexPath)

    $fullIndexPath = [IO.Path]::GetFullPath($IndexPath)
    Assert-OrdinaryLeaf -Path $fullIndexPath -Label 'Capability catalog index'
    $indexBytes = [IO.File]::ReadAllBytes($fullIndexPath)
    $index = ConvertFrom-JsonBytes -Bytes $indexBytes -Label 'Capability catalog index'
    Assert-ExactProperties -Value $index -Expected @('schema', 'capabilities') `
        -Label 'Capability catalog index'
    if (($index.schema -isnot [int] -and $index.schema -isnot [long]) -or
        [long]$index.schema -ne 1 -or $index.capabilities -isnot [Array] -or
        @($index.capabilities).Count -eq 0) {
        throw 'Capability catalog index has an unsupported schema or capability collection.'
    }

    $catalogRoot = [IO.Path]::GetDirectoryName($fullIndexPath)
    $seenSlugs = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $seenDefinitions = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $seenBlobs = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $capabilities = [System.Collections.Generic.List[object]]::new()

    foreach ($entry in @($index.capabilities)) {
        Assert-ExactProperties -Value $entry `
            -Expected @('slug', 'definition', 'type', 'definitionBlob') `
            -Label 'Capability catalog entry'
        $slug = [string]$entry.slug
        $definitionName = [string]$entry.definition
        $type = [string]$entry.type
        $definitionBlob = [string]$entry.definitionBlob
        if (-not (Test-CanonicalSlug -Value $slug) -or -not $seenSlugs.Add($slug)) {
            throw "Capability catalog slug '$slug' is invalid or duplicated."
        }
        if ($definitionName -cne "$slug.json" -or
            -not $seenDefinitions.Add($definitionName)) {
            throw "Capability catalog path '$definitionName' is not the canonical definition path for '$slug'."
        }
        if ($script:CapabilityTypes -cnotcontains $type) {
            throw "Capability '$slug' uses unsupported type '$type'."
        }
        if ($definitionBlob -cnotmatch '^[0-9a-f]{40}$' -or
            -not $seenBlobs.Add($definitionBlob)) {
            throw "Capability '$slug' definition blob is invalid or duplicated."
        }

        $exactFiles = @(Get-ChildItem -LiteralPath $catalogRoot -File | Where-Object {
            [string]$_.Name -ceq $definitionName
        })
        if ($exactFiles.Count -ne 1) {
            throw "Capability definition '$definitionName' is absent or has noncanonical case."
        }
        $definitionPath = [IO.Path]::GetFullPath($exactFiles[0].FullName)
        if (-not ([IO.Path]::GetDirectoryName($definitionPath)).Equals(
            $catalogRoot, [StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Capability definition '$definitionName' escapes the catalog root."
        }
        Assert-OrdinaryLeaf -Path $definitionPath `
            -Label "Capability definition '$definitionName'"
        $definitionBytes = [IO.File]::ReadAllBytes($definitionPath)
        $actualBlob = Get-MeAndAIGitBlobSha1 -Bytes $definitionBytes
        if ($actualBlob -cne $definitionBlob) {
            throw "Capability '$slug' definition blob does not match '$definitionName'."
        }
        $definition = ConvertFrom-JsonBytes -Bytes $definitionBytes `
            -Label "Capability definition '$slug'"
        Assert-CapabilityDefinition -Definition $definition -Slug $slug -Type $type

        $capability = [pscustomobject]@{
            Slug = $slug
            DefinitionPath = $definitionName
            Type = $type
            DefinitionBlob = $definitionBlob
            Definition = $definition
        }
        $capability.PSObject.TypeNames.Insert(0, 'MeAndAI.CapabilityDefinition')
        $capabilities.Add($capability)
    }

    $definitionFiles = @(Get-ChildItem -LiteralPath $catalogRoot -File -Filter '*.json' |
        Where-Object { [string]$_.Name -cne 'index.json' })
    if ($definitionFiles.Count -ne $seenDefinitions.Count) {
        throw 'Capability catalog root contains an unlisted JSON definition.'
    }
    foreach ($file in $definitionFiles) {
        if (-not $seenDefinitions.Contains([string]$file.Name)) {
            throw "Capability catalog root contains unlisted definition '$($file.Name)'."
        }
    }

    $catalog = [pscustomobject]@{
        Schema = 1
        IndexPath = $fullIndexPath
        IndexBlob = Get-MeAndAIGitBlobSha1 -Bytes $indexBytes
        CatalogDigest = Get-MeAndAISha256 -Bytes $indexBytes
        Capabilities = @($capabilities)
    }
    $catalog.PSObject.TypeNames.Insert(0, 'MeAndAI.CapabilityCatalog')
    return $catalog
}

function Assert-MeAndAICapabilityCatalogExtension {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$CurrentCatalog,
        [Parameter(Mandatory)]$TargetCatalog
    )

    Assert-CatalogObject -Catalog $CurrentCatalog
    Assert-CatalogObject -Catalog $TargetCatalog
    if ($TargetCatalog.Capabilities.Count -lt $CurrentCatalog.Capabilities.Count) {
        throw 'Target capability catalog removes immutable capability definitions.'
    }
    for ($index = 0; $index -lt $CurrentCatalog.Capabilities.Count; $index++) {
        $current = $CurrentCatalog.Capabilities[$index]
        $target = $TargetCatalog.Capabilities[$index]
        if ([string]$target.Slug -cne [string]$current.Slug -or
            [string]$target.DefinitionPath -cne [string]$current.DefinitionPath -or
            [string]$target.Type -cne [string]$current.Type -or
            [string]$target.DefinitionBlob -cne [string]$current.DefinitionBlob) {
            throw "Target capability catalog changes immutable prefix entry '$($current.Slug)'."
        }
    }
}

function Assert-MeAndAICapabilityCatalogChain {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object[]]$Catalogs)

    if (@($Catalogs).Count -eq 0) {
        throw 'Capability catalog chain must contain at least one catalog.'
    }
    foreach ($catalog in @($Catalogs)) {
        Assert-CatalogObject -Catalog $catalog
    }
    for ($index = 1; $index -lt @($Catalogs).Count; $index++) {
        Assert-MeAndAICapabilityCatalogExtension `
            -CurrentCatalog $Catalogs[$index - 1] -TargetCatalog $Catalogs[$index]
    }
}

function Test-CanonicalReviewIdentity {
    param([AllowNull()][string]$Value)
    return -not [string]::IsNullOrWhiteSpace($Value) -and $Value.Length -le 255 -and
        $Value -cmatch '^[A-Za-z0-9][A-Za-z0-9._:@/-]*$'
}

function Assert-ReviewAuthority {
    param([AllowNull()][string]$Value)

    $uri = $null
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.Length -gt 2048 -or
        -not [Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri) -or
        [string]$uri.Scheme -cne 'https') {
        throw 'Capability review authority must be one absolute HTTPS URI.'
    }
}

function Assert-ReviewedAt {
    param([AllowNull()][string]$Value)

    [DateTimeOffset]$parsed = [DateTimeOffset]::MinValue
    $styles = [Globalization.DateTimeStyles](
        [Globalization.DateTimeStyles]::AssumeUniversal -bor
        [Globalization.DateTimeStyles]::AdjustToUniversal
    )
    if ([string]::IsNullOrWhiteSpace($Value) -or
        -not [DateTimeOffset]::TryParseExact(
            $Value,
            $script:ReviewedAtFormat,
            [Globalization.CultureInfo]::InvariantCulture,
            $styles,
            [ref]$parsed
        ) -or $parsed.ToUniversalTime().ToString(
            $script:ReviewedAtFormat,
            [Globalization.CultureInfo]::InvariantCulture
        ) -cne $Value) {
        throw 'Capability review timestamp must be canonical UTC seconds.'
    }
}

function ConvertTo-ReviewedAtString {
    param([AllowNull()]$Value)

    if ($Value -is [DateTime]) {
        return $Value.ToUniversalTime().ToString(
            $script:ReviewedAtFormat,
            [Globalization.CultureInfo]::InvariantCulture
        )
    }
    if ($Value -is [DateTimeOffset]) {
        return $Value.ToUniversalTime().ToString(
            $script:ReviewedAtFormat,
            [Globalization.CultureInfo]::InvariantCulture
        )
    }
    return [string]$Value
}

function New-ValidatedLedgerEntry {
    param(
        [Parameter(Mandatory)]$Capability,
        [Parameter(Mandatory)][string]$Outcome,
        [Parameter(Mandatory)]$Evidence,
        [Parameter(Mandatory)][string]$ReviewIdentity,
        [Parameter(Mandatory)][string]$ReviewAuthority,
        [Parameter(Mandatory)][string]$ReviewedAt
    )

    Assert-CapabilityObject -Capability $Capability
    if ($script:TerminalOutcomes -cnotcontains $Outcome) {
        throw "Capability outcome '$Outcome' is not a terminal ledger outcome."
    }
    $normalizedEvidence = [string[]]@(Get-ValidatedStringArray -Value @($Evidence) `
        -Label "Capability '$($Capability.Slug)' evidence")
    [Array]::Sort($normalizedEvidence, [StringComparer]::Ordinal)
    if (-not (Test-CanonicalReviewIdentity -Value $ReviewIdentity)) {
        throw 'Capability review identity is not canonical.'
    }
    Assert-ReviewAuthority -Value $ReviewAuthority
    Assert-ReviewedAt -Value $ReviewedAt

    $review = [pscustomobject]@{
        identity = $ReviewIdentity
        authority = $ReviewAuthority
        reviewedAt = $ReviewedAt
    }
    $entry = [pscustomobject]@{
        Slug = [string]$Capability.Slug
        DefinitionBlob = [string]$Capability.DefinitionBlob
        Outcome = $Outcome
        Evidence = [string[]]$normalizedEvidence
        Review = $review
        ReviewIdentity = $ReviewIdentity
        ReviewAuthority = $ReviewAuthority
        ReviewedAt = $ReviewedAt
    }
    $entry.PSObject.TypeNames.Insert(0, 'MeAndAI.CapabilityLedgerEntry')
    return $entry
}

function New-MeAndAICapabilityLedgerEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Capability,
        [Parameter(Mandatory)][string]$Outcome,
        [Parameter(Mandatory)][string[]]$Evidence,
        [Parameter(Mandatory)][string]$ReviewIdentity,
        [Parameter(Mandatory)][string]$ReviewAuthority,
        [Parameter(Mandatory)][string]$ReviewedAt
    )

    return New-ValidatedLedgerEntry -Capability $Capability -Outcome $Outcome `
        -Evidence $Evidence -ReviewIdentity $ReviewIdentity `
        -ReviewAuthority $ReviewAuthority -ReviewedAt $ReviewedAt
}

function ConvertTo-JsonStringLiteral {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Value)
    return ($Value | ConvertTo-Json -Compress)
}

function ConvertTo-LedgerBytes {
    param([AllowEmptyCollection()][object[]]$Entries)

    $items = @($Entries | ForEach-Object {
        $evidence = @($_.Evidence | ForEach-Object {
            ConvertTo-JsonStringLiteral -Value ([string]$_)
        }) -join ','
        '{"slug":' + (ConvertTo-JsonStringLiteral -Value ([string]$_.Slug)) +
            ',"definitionBlob":' + (ConvertTo-JsonStringLiteral -Value ([string]$_.DefinitionBlob)) +
            ',"outcome":' + (ConvertTo-JsonStringLiteral -Value ([string]$_.Outcome)) +
            ',"evidence":[' + $evidence + ']' +
            ',"review":{"identity":' + (ConvertTo-JsonStringLiteral -Value ([string]$_.ReviewIdentity)) +
            ',"authority":' + (ConvertTo-JsonStringLiteral -Value ([string]$_.ReviewAuthority)) +
            ',"reviewedAt":' + (ConvertTo-JsonStringLiteral -Value ([string]$_.ReviewedAt)) + '}}'
    })
    $text = '{"schema":1,"assessments":[' + ($items -join ',') + "]}`n"
    return ,([Text.UTF8Encoding]::new($false).GetBytes($text))
}

function Assert-LedgerPrefix {
    param(
        [Parameter(Mandatory)]$Catalog,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Entries
    )

    Assert-CatalogObject -Catalog $Catalog
    if ($Entries.Count -gt $Catalog.Capabilities.Count) {
        throw 'Consumer capability ledger is longer than the installed catalog.'
    }
    for ($index = 0; $index -lt $Entries.Count; $index++) {
        $entry = $Entries[$index]
        $expected = $Catalog.Capabilities[$index]
        if ([string]$entry.Slug -cne [string]$expected.Slug -or
            [string]$entry.DefinitionBlob -cne [string]$expected.DefinitionBlob) {
            throw 'Consumer capability ledger is not the exact installed-catalog prefix.'
        }
    }
}

function ConvertTo-MeAndAICapabilityLedgerBytes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Catalog,
        [AllowEmptyCollection()][object[]]$Entries = @()
    )

    Assert-CatalogObject -Catalog $Catalog
    foreach ($entry in @($Entries)) {
        if ($entry.PSObject.TypeNames -cnotcontains 'MeAndAI.CapabilityLedgerEntry') {
            throw 'Ledger entries must be produced by New-MeAndAICapabilityLedgerEntry.'
        }
    }
    Assert-LedgerPrefix -Catalog $Catalog -Entries @($Entries)
    return ConvertTo-LedgerBytes -Entries @($Entries)
}

function Import-MeAndAICapabilityLedger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Catalog,
        [AllowNull()][byte[]]$Bytes = $null
    )

    Assert-CatalogObject -Catalog $Catalog
    if ($null -eq $Bytes) {
        $missing = [pscustomobject]@{
            Path = $script:LedgerPath
            Missing = $true
            Entries = @()
            Bytes = $null
        }
        $missing.PSObject.TypeNames.Insert(0, 'MeAndAI.CapabilityLedger')
        return $missing
    }

    $ledger = ConvertFrom-JsonBytes -Bytes $Bytes -Label 'Consumer capability ledger'
    Assert-ExactProperties -Value $ledger -Expected @('schema', 'assessments') `
        -Label 'Consumer capability ledger'
    if (($ledger.schema -isnot [int] -and $ledger.schema -isnot [long]) -or
        [long]$ledger.schema -ne 1 -or $ledger.assessments -isnot [Array]) {
        throw 'Consumer capability ledger has an unsupported schema or assessment collection.'
    }

    $entries = [System.Collections.Generic.List[object]]::new()
    $seenSlugs = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($rawEntry in @($ledger.assessments)) {
        Assert-ExactProperties -Value $rawEntry -Expected @(
            'slug', 'definitionBlob', 'outcome', 'evidence', 'review'
        ) -Label 'Consumer capability ledger entry'
        Assert-ExactProperties -Value $rawEntry.review `
            -Expected @('identity', 'authority', 'reviewedAt') `
            -Label 'Consumer capability ledger review'
        $slug = [string]$rawEntry.slug
        if (-not (Test-CanonicalSlug -Value $slug) -or -not $seenSlugs.Add($slug)) {
            throw "Consumer capability ledger slug '$slug' is invalid or duplicated."
        }
        $capability = if ($entries.Count -lt $Catalog.Capabilities.Count) {
            $Catalog.Capabilities[$entries.Count]
        }
        else { $Catalog.Capabilities[0] }
        if ([string]$rawEntry.definitionBlob -cnotmatch '^[0-9a-f]{40}$') {
            throw "Consumer capability ledger definition blob for '$slug' is invalid."
        }
        $normalizedEvidence = @(Get-ValidatedStringArray -Value $rawEntry.evidence `
            -Label "Consumer capability ledger '$slug' evidence" -RequireOrdinalOrder)
        $entry = New-ValidatedLedgerEntry -Capability $capability `
            -Outcome ([string]$rawEntry.outcome) -Evidence $normalizedEvidence `
            -ReviewIdentity ([string]$rawEntry.review.identity) `
            -ReviewAuthority ([string]$rawEntry.review.authority) `
            -ReviewedAt (ConvertTo-ReviewedAtString -Value $rawEntry.review.reviewedAt)
        $entry.Slug = $slug
        $entry.DefinitionBlob = [string]$rawEntry.definitionBlob
        $entries.Add($entry)
    }

    Assert-LedgerPrefix -Catalog $Catalog -Entries @($entries)
    $canonicalBytes = ConvertTo-LedgerBytes -Entries @($entries)
    if (-not (Test-MeAndAIByteArrayEqual -Left $Bytes -Right $canonicalBytes)) {
        throw 'Consumer capability ledger is not in canonical UTF-8 JSON form.'
    }
    $result = [pscustomobject]@{
        Path = $script:LedgerPath
        Missing = $false
        Entries = @($entries)
        Bytes = $Bytes
    }
    $result.PSObject.TypeNames.Insert(0, 'MeAndAI.CapabilityLedger')
    return $result
}

function Get-MeAndAICapabilityPending {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Catalog,
        [AllowNull()][byte[]]$LedgerBytes = $null
    )

    $ledger = Import-MeAndAICapabilityLedger -Catalog $Catalog -Bytes $LedgerBytes
    return @($Catalog.Capabilities | Select-Object -Skip $ledger.Entries.Count)
}

function Resolve-MeAndAICapabilityAssessment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Capability,
        [Parameter(Mandatory)][string]$Applicability,
        [Parameter(Mandatory)][string]$Conformance,
        [AllowEmptyString()][string]$EvidenceKind = '',
        [AllowEmptyCollection()][string[]]$Evidence = @(),
        [AllowEmptyString()][string]$ReviewIdentity = '',
        [Parameter(Mandatory)][string]$AdoptionPlan
    )

    Assert-CapabilityObject -Capability $Capability
    if (@('Applicable', 'NotApplicable', 'Unknown') -cnotcontains $Applicability) {
        throw "Capability applicability '$Applicability' is unsupported."
    }
    if (@('Conforming', 'NonConforming', 'Unknown') -cnotcontains $Conformance) {
        throw "Capability conformance '$Conformance' is unsupported."
    }
    if (@('Ready', 'Ambiguous', 'NotRequired') -cnotcontains $AdoptionPlan) {
        throw "Capability adoption plan '$AdoptionPlan' is unsupported."
    }
    $normalizedEvidence = [string[]]@(Get-ValidatedStringArray -Value @($Evidence) `
        -Label "Capability '$($Capability.Slug)' assessment evidence" -AllowEmpty)
    [Array]::Sort($normalizedEvidence, [StringComparer]::Ordinal)
    $expectedEvidenceKind = [string]$script:EvidenceKinds[[string]$Capability.Type]
    $authorityMatches = $EvidenceKind -ceq $expectedEvidenceKind
    $hasEvidence = $normalizedEvidence.Count -gt 0
    $hasReview = Test-CanonicalReviewIdentity -Value $ReviewIdentity

    $outcome = 'ReviewRequired'
    if ($Applicability -ceq 'NotApplicable') {
        if ($Conformance -ceq 'Unknown' -and $AdoptionPlan -ceq 'NotRequired' -and
            $authorityMatches -and $hasEvidence -and $hasReview) {
            $outcome = 'NotApplicable'
        }
    }
    elseif ($Applicability -ceq 'Applicable') {
        if ($Conformance -ceq 'Conforming' -and $AdoptionPlan -ceq 'NotRequired' -and
            $authorityMatches -and $hasEvidence -and $hasReview) {
            $outcome = 'Conforming'
        }
        elseif ($Conformance -ceq 'NonConforming' -and $AdoptionPlan -ceq 'Ready' -and
            $authorityMatches -and $hasEvidence) {
            $outcome = 'AdoptionRequired'
        }
    }

    return [pscustomobject]@{
        Slug = [string]$Capability.Slug
        DefinitionBlob = [string]$Capability.DefinitionBlob
        Type = [string]$Capability.Type
        RequiredEvidenceKind = $expectedEvidenceKind
        EvidenceKind = $EvidenceKind
        Evidence = [string[]]$normalizedEvidence
        ReviewIdentity = $ReviewIdentity
        AdoptionPlan = $AdoptionPlan
        Outcome = $outcome
        Terminal = $script:TerminalOutcomes -ccontains $outcome
    }
}

Export-ModuleMember -Function @(
    'Import-MeAndAICapabilityCatalog',
    'Assert-MeAndAICapabilityCatalogExtension',
    'Assert-MeAndAICapabilityCatalogChain',
    'New-MeAndAICapabilityLedgerEntry',
    'ConvertTo-MeAndAICapabilityLedgerBytes',
    'Import-MeAndAICapabilityLedger',
    'Get-MeAndAICapabilityPending',
    'Resolve-MeAndAICapabilityAssessment'
)
