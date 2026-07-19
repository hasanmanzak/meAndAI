$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
Import-Module (Join-Path $root 'scripts/MeAndAI.CapabilityCatalog.psm1') -Force

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-Equal {
    param($Actual, $Expected, [string]$Message)
    if ($Actual -cne $Expected) {
        throw "$Message Expected '$Expected', observed '$Actual'."
    }
}

function Assert-SequenceEqual {
    param([object[]]$Actual, [object[]]$Expected, [string]$Message)
    if ($Actual.Count -ne $Expected.Count) {
        throw "$Message Count differs: $($Actual.Count) != $($Expected.Count)."
    }
    for ($index = 0; $index -lt $Actual.Count; $index++) {
        if ([string]$Actual[$index] -cne [string]$Expected[$index]) {
            throw "$Message Element $index differs: '$($Actual[$index])' != '$($Expected[$index])'."
        }
    }
}

function Assert-ThrowsLike {
    param([scriptblock]$Action, [string]$Pattern, [string]$Message)
    try {
        & $Action
    }
    catch {
        if ($_.Exception.Message -like $Pattern) { return }
        throw "$Message Unexpected error: $($_.Exception.Message)"
    }
    throw "$Message No error was thrown."
}

function Get-TestGitBlobSha {
    param([byte[]]$Bytes)

    $header = [Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
    $payload = [byte[]]::new($header.Length + $Bytes.Length)
    [Array]::Copy($header, 0, $payload, 0, $header.Length)
    [Array]::Copy($Bytes, 0, $payload, $header.Length, $Bytes.Length)
    $algorithm = [Security.Cryptography.SHA1]::Create()
    try {
        return -join @($algorithm.ComputeHash($payload) | ForEach-Object {
            $_.ToString('x2', [Globalization.CultureInfo]::InvariantCulture)
        })
    }
    finally {
        $algorithm.Dispose()
    }
}

function ConvertTo-TestJsonBytes {
    param($Value, [bool]$Bom = $false, [bool]$CrLf = $false)

    $text = (($Value | ConvertTo-Json -Depth 12).TrimEnd() + "`n").Replace("`r`n", "`n")
    if ($CrLf) { $text = $text.Replace("`n", "`r`n") }
    $body = [Text.UTF8Encoding]::new($false).GetBytes($text)
    if (-not $Bom) { return ,$body }
    $result = [byte[]]::new($body.Length + 3)
    $result[0] = 0xEF; $result[1] = 0xBB; $result[2] = 0xBF
    [Array]::Copy($body, 0, $result, 3, $body.Length)
    return ,$result
}

function New-TestDefinition {
    param(
        [string]$Slug,
        [ValidateSet('Deterministic', 'DeclarativeMigration', 'Semantic', 'Manual')]
        [string]$Type
    )

    return [ordered]@{
        schema = 1
        slug = $Slug
        type = $Type
        title = "Test definition for $Slug"
        applicability = [ordered]@{
            condition = 'automated-test-or-validation-surface'
            description = 'The repository has an automated test or validation surface.'
        }
        requirements = @(
            [ordered]@{
                id = 'bounded-test-ownership'
                statement = 'Every test has one explicit capability owner.'
            }
        )
        evidence = [ordered]@{
            conforming = @('Reviewed evidence maps the repository to every requirement.')
            notApplicable = @('Reviewed evidence proves that the applicability condition is false.')
        }
    }
}

function New-TestCatalog {
    param(
        [string]$Directory,
        [object[]]$Definitions,
        [scriptblock]$MutateIndex = $null,
        [scriptblock]$MutateDefinitions = $null,
        [bool]$IndexBom = $false,
        [bool]$IndexCrLf = $false
    )

    [IO.Directory]::CreateDirectory($Directory) | Out-Null
    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($specification in @($Definitions)) {
        $definition = New-TestDefinition -Slug ([string]$specification.Slug) `
            -Type ([string]$specification.Type)
        if ($null -ne $MutateDefinitions) {
            & $MutateDefinitions $definition $specification
        }
        $definitionBytes = ConvertTo-TestJsonBytes -Value $definition
        $definitionName = "$($specification.Slug).json"
        [IO.File]::WriteAllBytes((Join-Path $Directory $definitionName), $definitionBytes)
        $entries.Add([ordered]@{
            slug = [string]$specification.Slug
            definition = $definitionName
            type = [string]$specification.Type
            definitionBlob = Get-TestGitBlobSha -Bytes $definitionBytes
        })
    }
    $index = [ordered]@{ schema = 1; capabilities = @($entries) }
    if ($null -ne $MutateIndex) { & $MutateIndex $index }
    [IO.File]::WriteAllBytes(
        (Join-Path $Directory 'index.json'),
        (ConvertTo-TestJsonBytes -Value $index -Bom $IndexBom -CrLf $IndexCrLf)
    )
    return (Join-Path $Directory 'index.json')
}

function New-ReviewedEntry {
    param($Catalog, [string]$Outcome = 'Conforming')

    return New-MeAndAICapabilityLedgerEntry `
        -Capability $Catalog.Capabilities[0] `
        -Outcome $Outcome `
        -Evidence @('https://github.com/example/repo/pull/12', 'docs/test-evidence.md') `
        -ReviewIdentity 'github:maintainer' `
        -ReviewAuthority 'https://github.com/example/repo/pull/12#pullrequestreview-34' `
        -ReviewedAt '2026-07-19T10:20:30Z'
}

# TEST-0134: the repository catalog is one exact typed immutable definition.
$catalog = Import-MeAndAICapabilityCatalog `
    -IndexPath (Join-Path $root 'capabilities/index.json')
Assert-Equal $catalog.Schema 1 'TEST-0134 catalog schema differs.'
Assert-Equal $catalog.Capabilities.Count 1 'TEST-0134 catalog count differs.'
Assert-Equal $catalog.Capabilities[0].Slug 'test-architecture' `
    'TEST-0134 first capability slug differs.'
Assert-Equal $catalog.Capabilities[0].Type 'Semantic' `
    'TEST-0134 first capability type differs.'
Assert-True ([string]$catalog.Capabilities[0].DefinitionBlob -cmatch '^[0-9a-f]{40}$') `
    'TEST-0134 definition evidence is not one exact Git blob SHA.'
Assert-SequenceEqual -Actual @($catalog.Capabilities[0].Definition.requirements.id) `
    -Expected @(
        'capability-based-physical-ownership',
        'feature-based-scenario-traceability',
        'deterministic-recursive-discovery',
        'small-common-infrastructure',
        'separate-suite-processes',
        'capability-local-fixtures'
    ) -Message 'TEST-0134 test-architecture requirements differ.'

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) `
    ('meandai-capability-catalog-' + [guid]::NewGuid().ToString('N'))
try {
    $allTypesPath = New-TestCatalog -Directory (Join-Path $fixtureRoot 'all-types') `
        -Definitions @(
            [pscustomobject]@{ Slug = 'alpha'; Type = 'Deterministic' },
            [pscustomobject]@{ Slug = 'beta'; Type = 'DeclarativeMigration' },
            [pscustomobject]@{ Slug = 'gamma'; Type = 'Semantic' },
            [pscustomobject]@{ Slug = 'omega'; Type = 'Manual' }
        )
    $allTypes = Import-MeAndAICapabilityCatalog -IndexPath $allTypesPath
    Assert-SequenceEqual -Actual @($allTypes.Capabilities.Type) -Expected @(
        'Deterministic', 'DeclarativeMigration', 'Semantic', 'Manual'
    ) -Message 'TEST-0134 supported type order differs.'

    $predecessorPath = New-TestCatalog -Directory (Join-Path $fixtureRoot 'predecessor') `
        -Definitions @([pscustomobject]@{ Slug = 'alpha'; Type = 'Deterministic' })
    $predecessor = Import-MeAndAICapabilityCatalog -IndexPath $predecessorPath
    Assert-MeAndAICapabilityCatalogExtension -CurrentCatalog $predecessor `
        -TargetCatalog $allTypes
    Assert-MeAndAICapabilityCatalogChain -Catalogs @($predecessor, $allTypes, $allTypes)

    $rewriteDirectory = Join-Path $fixtureRoot 'rewrite'
    $rewritePath = New-TestCatalog -Directory $rewriteDirectory -Definitions @(
        [pscustomobject]@{ Slug = 'alpha'; Type = 'Deterministic' },
        [pscustomobject]@{ Slug = 'beta'; Type = 'DeclarativeMigration' },
        [pscustomobject]@{ Slug = 'gamma'; Type = 'Semantic' },
        [pscustomobject]@{ Slug = 'omega'; Type = 'Manual' }
    ) -MutateDefinitions {
        param($Definition, $Specification)
        if ([string]$Specification.Slug -ceq 'alpha') {
            $Definition.title = 'Rewritten alpha definition'
        }
    }
    $rewrite = Import-MeAndAICapabilityCatalog -IndexPath $rewritePath
    Assert-ThrowsLike -Action {
        Assert-MeAndAICapabilityCatalogExtension -CurrentCatalog $predecessor `
            -TargetCatalog $rewrite
    } -Pattern "*changes immutable prefix entry 'alpha'*" `
        -Message 'TEST-0134 compatible extension accepted a rewritten definition.'

    $removedPath = New-TestCatalog -Directory (Join-Path $fixtureRoot 'removed') `
        -Definitions @([pscustomobject]@{ Slug = 'alpha'; Type = 'Deterministic' })
    $removed = Import-MeAndAICapabilityCatalog -IndexPath $removedPath
    Assert-ThrowsLike -Action {
        Assert-MeAndAICapabilityCatalogExtension -CurrentCatalog $allTypes `
            -TargetCatalog $removed
    } -Pattern '*removes immutable capability definitions*' `
        -Message 'TEST-0134 compatible extension accepted a removed definition.'

    $malformedCases = @(
        [pscustomobject]@{
            Name = 'duplicate-slug'
            Index = { param($Index) $Index.capabilities += $Index.capabilities[0] }
            Definitions = @([pscustomobject]@{ Slug = 'alpha'; Type = 'Deterministic' })
            Pattern = '*invalid or duplicated*'
        },
        [pscustomobject]@{
            Name = 'uppercase-slug'
            Index = { param($Index) $Index.capabilities[0].slug = 'Alpha' }
            Definitions = @([pscustomobject]@{ Slug = 'alpha'; Type = 'Deterministic' })
            Pattern = '*invalid or duplicated*'
        },
        [pscustomobject]@{
            Name = 'unsafe-path'
            Index = { param($Index) $Index.capabilities[0].definition = '../alpha.json' }
            Definitions = @([pscustomobject]@{ Slug = 'alpha'; Type = 'Deterministic' })
            Pattern = '*not the canonical definition path*'
        },
        [pscustomobject]@{
            Name = 'unknown-type'
            Index = { param($Index) $Index.capabilities[0].type = 'Automatic' }
            Definitions = @([pscustomobject]@{ Slug = 'alpha'; Type = 'Deterministic' })
            Pattern = '*unsupported type*'
        },
        [pscustomobject]@{
            Name = 'blob-drift'
            Index = { param($Index) $Index.capabilities[0].definitionBlob = ('0' * 40) }
            Definitions = @([pscustomobject]@{ Slug = 'alpha'; Type = 'Deterministic' })
            Pattern = '*blob does not match*'
        },
        [pscustomobject]@{
            Name = 'definition-slug-drift'
            Index = $null
            DefinitionMutation = {
                param($Definition, $Specification)
                $Definition.slug = 'different'
            }
            Definitions = @([pscustomobject]@{ Slug = 'alpha'; Type = 'Deterministic' })
            Pattern = '*identity or type does not match*'
        },
        [pscustomobject]@{
            Name = 'duplicate-requirement'
            Index = $null
            DefinitionMutation = {
                param($Definition, $Specification)
                $Definition.requirements += $Definition.requirements[0]
            }
            Definitions = @([pscustomobject]@{ Slug = 'alpha'; Type = 'Deterministic' })
            Pattern = '*requirement ID*invalid or duplicated*'
        }
    )
    foreach ($case in $malformedCases) {
        $definitionMutation = if (
            $case.PSObject.Properties.Name -ccontains 'DefinitionMutation'
        ) { $case.DefinitionMutation } else { $null }
        $casePath = New-TestCatalog -Directory (Join-Path $fixtureRoot $case.Name) `
            -Definitions $case.Definitions -MutateIndex $case.Index `
            -MutateDefinitions $definitionMutation
        Assert-ThrowsLike -Action {
            Import-MeAndAICapabilityCatalog -IndexPath $casePath
        } -Pattern $case.Pattern `
            -Message "TEST-0134 malformed case '$($case.Name)' was accepted."
    }

    foreach ($formatCase in @(
        [pscustomobject]@{ Name = 'index-bom'; Bom = $true; CrLf = $false; Pattern = '*without a byte-order mark*' },
        [pscustomobject]@{ Name = 'index-crlf'; Bom = $false; CrLf = $true; Pattern = '*must use LF line endings*' }
    )) {
        $formatPath = New-TestCatalog -Directory (Join-Path $fixtureRoot $formatCase.Name) `
            -Definitions @([pscustomobject]@{ Slug = 'alpha'; Type = 'Deterministic' }) `
            -IndexBom $formatCase.Bom -IndexCrLf $formatCase.CrLf
        Assert-ThrowsLike -Action {
            Import-MeAndAICapabilityCatalog -IndexPath $formatPath
        } -Pattern $formatCase.Pattern `
            -Message "TEST-0134 malformed format '$($formatCase.Name)' was accepted."
    }

    $entry = New-ReviewedEntry -Catalog $catalog
    Assert-SequenceEqual -Actual @($entry.Evidence) -Expected @(
        'docs/test-evidence.md', 'https://github.com/example/repo/pull/12'
    ) -Message 'TEST-0134 ledger evidence order is not canonical.'
    $ledgerBytes = ConvertTo-MeAndAICapabilityLedgerBytes -Catalog $catalog `
        -Entries @($entry)
    $ledger = Import-MeAndAICapabilityLedger -Catalog $catalog -Bytes $ledgerBytes
    Assert-Equal $ledger.Path '.ai/meandai-capabilities-state.json' `
        'TEST-0134 ledger path differs.'
    Assert-Equal $ledger.Entries.Count 1 'TEST-0134 ledger entry count differs.'
    Assert-Equal $ledger.Entries[0].Outcome 'Conforming' `
        'TEST-0134 terminal outcome differs.'
    $terminalPending = @(Get-MeAndAICapabilityPending -Catalog $catalog `
        -LedgerBytes $ledgerBytes)
    Assert-Equal $terminalPending.Count 0 `
        'TEST-0134 terminal ledger was not idempotent.'

    $missingLedger = Import-MeAndAICapabilityLedger -Catalog $catalog -Bytes $null
    Assert-True $missingLedger.Missing 'TEST-0134 missing ledger was not represented explicitly.'
    $missingPending = @(Get-MeAndAICapabilityPending -Catalog $catalog)
    Assert-Equal $missingPending.Count 1 `
        'TEST-0134 missing ledger did not expose the pending capability.'
    $emptyLedgerBytes = ConvertTo-MeAndAICapabilityLedgerBytes -Catalog $catalog `
        -Entries @()
    $emptyLedger = Import-MeAndAICapabilityLedger -Catalog $catalog `
        -Bytes $emptyLedgerBytes
    Assert-True (-not $emptyLedger.Missing) `
        'TEST-0134 canonical empty ledger was treated as missing.'
    Assert-Equal $emptyLedger.Entries.Count 0 `
        'TEST-0134 canonical empty ledger did not preserve the exact prefix.'

    $notApplicableEntry = New-ReviewedEntry -Catalog $catalog -Outcome 'NotApplicable'
    $notApplicableBytes = ConvertTo-MeAndAICapabilityLedgerBytes -Catalog $catalog `
        -Entries @($notApplicableEntry)
    Assert-Equal (Import-MeAndAICapabilityLedger -Catalog $catalog `
        -Bytes $notApplicableBytes).Entries[0].Outcome 'NotApplicable' `
        'TEST-0134 reviewed not-applicable evidence was rejected.'

    foreach ($openOutcome in @('AdoptionRequired', 'ReviewRequired')) {
        Assert-ThrowsLike -Action {
            New-MeAndAICapabilityLedgerEntry -Capability $catalog.Capabilities[0] `
                -Outcome $openOutcome -Evidence @('docs/evidence.md') `
                -ReviewIdentity 'github:maintainer' `
                -ReviewAuthority 'https://github.com/example/repo/pull/12' `
                -ReviewedAt '2026-07-19T10:20:30Z'
        } -Pattern '*is not a terminal ledger outcome*' `
            -Message "TEST-0134 open outcome '$openOutcome' entered the ledger."
    }

    $canonicalLedgerText = [Text.UTF8Encoding]::new($false, $true).GetString($ledgerBytes)
    foreach ($livePinName in @('protocolVersion', 'targetRef', 'release')) {
        $driftedText = $canonicalLedgerText.Replace(
            '{"schema":1,',
            ('{"schema":1,"' + $livePinName + '":"v0.12.0",')
        )
        Assert-ThrowsLike -Action {
            Import-MeAndAICapabilityLedger -Catalog $catalog `
                -Bytes ([Text.UTF8Encoding]::new($false).GetBytes($driftedText))
        } -Pattern '*unsupported property set*' `
            -Message "TEST-0134 ledger duplicated live pin '$livePinName'."
    }

    $driftedBlobText = $canonicalLedgerText.Replace(
        [string]$catalog.Capabilities[0].DefinitionBlob,
        ('0' * 40)
    )
    Assert-ThrowsLike -Action {
        Import-MeAndAICapabilityLedger -Catalog $catalog `
            -Bytes ([Text.UTF8Encoding]::new($false).GetBytes($driftedBlobText))
    } -Pattern '*not the exact installed-catalog prefix*' `
        -Message 'TEST-0134 drifted definition blob entered the ledger.'

    $nonCanonicalLedger = $canonicalLedgerText.Replace(
        '"evidence":["docs/test-evidence.md","https://github.com/example/repo/pull/12"]',
        '"evidence":["https://github.com/example/repo/pull/12","docs/test-evidence.md"]'
    )
    Assert-ThrowsLike -Action {
        Import-MeAndAICapabilityLedger -Catalog $catalog `
            -Bytes ([Text.UTF8Encoding]::new($false).GetBytes($nonCanonicalLedger))
    } -Pattern '*must be in ordinal order*' `
        -Message 'TEST-0134 noncanonical ledger ordering was accepted.'

    # TEST-0135: every type uses its declared authority model and returns only
    # the four assessment outcomes; only reviewed terminal evidence serializes.
    $expectedEvidenceKinds = [ordered]@{
        Deterministic = 'DeterministicEvidence'
        DeclarativeMigration = 'MigrationLedger'
        Semantic = 'SemanticReview'
        Manual = 'ManualEvidence'
    }
    foreach ($capability in @($allTypes.Capabilities)) {
        $evidenceKind = [string]$expectedEvidenceKinds[[string]$capability.Type]
        $conforming = Resolve-MeAndAICapabilityAssessment -Capability $capability `
            -Applicability Applicable -Conformance Conforming `
            -EvidenceKind $evidenceKind -Evidence @('docs/conformance.md') `
            -ReviewIdentity 'github:maintainer' -AdoptionPlan NotRequired
        Assert-Equal $conforming.Outcome 'Conforming' `
            "TEST-0135 conforming $($capability.Type) outcome differs."
        Assert-True $conforming.Terminal `
            "TEST-0135 conforming $($capability.Type) outcome is not terminal."

        $notApplicable = Resolve-MeAndAICapabilityAssessment -Capability $capability `
            -Applicability NotApplicable -Conformance Unknown `
            -EvidenceKind $evidenceKind -Evidence @('docs/applicability.md') `
            -ReviewIdentity 'github:maintainer' -AdoptionPlan NotRequired
        Assert-Equal $notApplicable.Outcome 'NotApplicable' `
            "TEST-0135 inapplicable $($capability.Type) outcome differs."
        Assert-True $notApplicable.Terminal `
            "TEST-0135 inapplicable $($capability.Type) outcome is not terminal."

        $adoption = Resolve-MeAndAICapabilityAssessment -Capability $capability `
            -Applicability Applicable -Conformance NonConforming `
            -EvidenceKind $evidenceKind -Evidence @('docs/gap.md') `
            -AdoptionPlan Ready
        Assert-Equal $adoption.Outcome 'AdoptionRequired' `
            "TEST-0135 nonconforming $($capability.Type) outcome differs."
        Assert-True (-not $adoption.Terminal) `
            "TEST-0135 adoption-required $($capability.Type) outcome became terminal."

        foreach ($ambiguous in @(
            @{ Applicability = 'Unknown'; Conformance = 'Unknown'; Kind = $evidenceKind; Evidence = @(); Review = ''; Plan = 'Ambiguous' },
            @{ Applicability = 'Applicable'; Conformance = 'Unknown'; Kind = $evidenceKind; Evidence = @('docs/partial.md'); Review = ''; Plan = 'Ambiguous' },
            @{ Applicability = 'Applicable'; Conformance = 'Conforming'; Kind = 'WrongAuthority'; Evidence = @('docs/evidence.md'); Review = 'github:maintainer'; Plan = 'NotRequired' },
            @{ Applicability = 'Applicable'; Conformance = 'Conforming'; Kind = $evidenceKind; Evidence = @(); Review = 'github:maintainer'; Plan = 'NotRequired' },
            @{ Applicability = 'Applicable'; Conformance = 'Conforming'; Kind = $evidenceKind; Evidence = @('docs/evidence.md'); Review = ''; Plan = 'NotRequired' },
            @{ Applicability = 'Applicable'; Conformance = 'NonConforming'; Kind = $evidenceKind; Evidence = @('docs/gap.md'); Review = ''; Plan = 'Ambiguous' }
        )) {
            $reviewRequired = Resolve-MeAndAICapabilityAssessment `
                -Capability $capability `
                -Applicability $ambiguous.Applicability `
                -Conformance $ambiguous.Conformance `
                -EvidenceKind $ambiguous.Kind -Evidence $ambiguous.Evidence `
                -ReviewIdentity $ambiguous.Review -AdoptionPlan $ambiguous.Plan
            Assert-Equal $reviewRequired.Outcome 'ReviewRequired' `
                "TEST-0135 ambiguous $($capability.Type) state did not fail closed."
            Assert-True (-not $reviewRequired.Terminal) `
                "TEST-0135 review-required $($capability.Type) outcome became terminal."
        }
    }

    $outcomes = @(
        Resolve-MeAndAICapabilityAssessment -Capability $allTypes.Capabilities[0] `
            -Applicability Applicable -Conformance Conforming `
            -EvidenceKind DeterministicEvidence -Evidence @('docs/pass.md') `
            -ReviewIdentity 'github:maintainer' -AdoptionPlan NotRequired
        Resolve-MeAndAICapabilityAssessment -Capability $allTypes.Capabilities[0] `
            -Applicability NotApplicable -Conformance Unknown `
            -EvidenceKind DeterministicEvidence -Evidence @('docs/na.md') `
            -ReviewIdentity 'github:maintainer' -AdoptionPlan NotRequired
        Resolve-MeAndAICapabilityAssessment -Capability $allTypes.Capabilities[0] `
            -Applicability Applicable -Conformance NonConforming `
            -EvidenceKind DeterministicEvidence -Evidence @('docs/gap.md') `
            -AdoptionPlan Ready
        Resolve-MeAndAICapabilityAssessment -Capability $allTypes.Capabilities[0] `
            -Applicability Unknown -Conformance Unknown -AdoptionPlan Ambiguous
    ) | ForEach-Object { [string]$_.Outcome } | Sort-Object -Unique
    Assert-SequenceEqual -Actual $outcomes -Expected @(
        'AdoptionRequired', 'Conforming', 'NotApplicable', 'ReviewRequired'
    ) -Message 'TEST-0135 resolver exposed an unexpected outcome set.'
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}

Write-Host 'Capability catalog and assessment tests passed.'

$evidenceModule = Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1'
$authorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
if ((Test-Path -LiteralPath $evidenceModule -PathType Leaf) -and
    (Test-Path -LiteralPath $authorityPath -PathType Leaf)) {
    $authority = Import-PowerShellDataFile -LiteralPath $authorityPath
    $owner = 'tests/capabilities/capability-adoption/capability-catalog.tests.ps1'
    if (@($authority.Authorities | Where-Object {
        [string]$_.Owner -ceq $owner
    }).Count -eq 1) {
        Import-Module $evidenceModule -Force
        $scenarioResult = New-MeAndAIScenarioResult `
            -Owner $owner -SourcePaths @($PSCommandPath) `
            -AuthorityPath $authorityPath
        Write-Host ('MEANDAI_SCENARIO_RESULTS=' + `
            ($scenarioResult | ConvertTo-Json -Compress))
    }
}
