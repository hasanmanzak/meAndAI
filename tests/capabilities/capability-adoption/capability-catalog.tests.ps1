$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
Import-Module (Join-Path $root 'scripts/MeAndAI.CapabilityCatalog.psm1') -Force
Import-Module (Join-Path $root 'scripts/MeAndAI.RepositoryEvidence.psm1') -Force

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

function Assert-BytesEqual {
    param([byte[]]$Actual, [byte[]]$Expected, [string]$Message)
    if ($null -eq $Actual -or $null -eq $Expected) {
        if ($null -eq $Actual -and $null -eq $Expected) { return }
        throw "$Message One byte sequence is null."
    }
    if ($Actual.Length -ne $Expected.Length) {
        throw "$Message Length differs: $($Actual.Length) != $($Expected.Length)."
    }
    for ($index = 0; $index -lt $Actual.Length; $index++) {
        if ($Actual[$index] -ne $Expected[$index]) {
            throw "$Message Byte $index differs: $($Actual[$index]) != $($Expected[$index])."
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

function Invoke-TestGit {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Arguments,
        [int[]]$AllowedExitCodes = @(0)
    )

    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& git -C $Repository @Arguments 2>&1 | ForEach-Object {
            [string]$_
        })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($AllowedExitCodes -cnotcontains $exitCode) {
        throw "Test git '$($Arguments -join ' ')' failed with exit code $exitCode. $($output -join "`n")"
    }
    return [pscustomobject][ordered]@{
        ExitCode = $exitCode
        Text = ($output -join "`n").Trim()
    }
}

function Initialize-TestGitRepository {
    param(
        [Parameter(Mandatory)][string]$Directory,
        [bool]$AutoCrLf = $false
    )

    [IO.Directory]::CreateDirectory($Directory) | Out-Null
    [void](Invoke-TestGit -Repository $Directory -Arguments @('init', '--quiet'))
    [void](Invoke-TestGit -Repository $Directory -Arguments @(
        'config', 'user.name', 'meAndAI Test'
    ))
    [void](Invoke-TestGit -Repository $Directory -Arguments @(
        'config', 'user.email', 'meandai-test@example.invalid'
    ))
    [void](Invoke-TestGit -Repository $Directory -Arguments @(
        'config', 'core.autocrlf', $AutoCrLf.ToString().ToLowerInvariant()
    ))
    [void](Invoke-TestGit -Repository $Directory -Arguments @(
        'config', 'commit.gpgsign', 'false'
    ))
}

function Assert-TestRepositoryEvidenceRerun {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Head,
        [Parameter(Mandatory)][string]$ExpectedSource,
        [Parameter(Mandatory)][byte[]]$ExpectedBytes,
        [Parameter(Mandatory)][string]$Message
    )

    $statusBefore = (Invoke-TestGit -Repository $Repository -Arguments @(
        'status', '--porcelain=v1', '--untracked-files=all'
    )).Text
    $first = Get-MeAndAIRepositoryEvidence -RepositoryRoot $Repository `
        -RelativePath $RelativePath -Head $Head
    $second = Get-MeAndAIRepositoryEvidence -RepositoryRoot $Repository `
        -RelativePath $RelativePath -Head $Head
    Assert-Equal $first.Source $ExpectedSource "$Message source differs."
    Assert-Equal $second.Source $ExpectedSource "$Message rerun source differs."
    Assert-BytesEqual -Actual $first.Bytes -Expected $ExpectedBytes `
        -Message "$Message bytes differ."
    Assert-BytesEqual -Actual $second.Bytes -Expected $ExpectedBytes `
        -Message "$Message rerun bytes differ."
    Assert-Equal (Invoke-TestGit -Repository $Repository -Arguments @(
        'status', '--porcelain=v1', '--untracked-files=all'
    )).Text $statusBefore "$Message resolution mutated repository state."
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
    param(
        $Catalog,
        [int]$CapabilityIndex = 0,
        [string]$Outcome = 'Conforming'
    )

    return New-MeAndAICapabilityLedgerEntry `
        -Capability $Catalog.Capabilities[$CapabilityIndex] `
        -Outcome $Outcome `
        -Evidence @('https://github.com/example/repo/pull/12', 'docs/test-evidence.md') `
        -ReviewIdentity 'github:maintainer' `
        -ReviewAuthority 'https://github.com/example/repo/pull/12#pullrequestreview-34' `
        -ReviewedAt '2026-07-19T10:20:30Z'
}

# TEST-0134: the repository catalog retains the exact typed immutable
# test-architecture definition as its first entry.
$catalog = Import-MeAndAICapabilityCatalog `
    -IndexPath (Join-Path $root 'capabilities/index.json')
Assert-Equal $catalog.Schema 1 'TEST-0134 catalog schema differs.'
Assert-Equal $catalog.Capabilities[0].Slug 'test-architecture' `
    'TEST-0134 first capability slug differs.'
Assert-Equal $catalog.Capabilities[0].Type 'Semantic' `
    'TEST-0134 first capability type differs.'
Assert-Equal $catalog.Capabilities[0].DefinitionPath 'test-architecture.json' `
    'TEST-0134 first capability definition path differs.'
Assert-Equal $catalog.Capabilities[0].DefinitionBlob `
    '9a3a999f05abbbb4ee710f14d82fb26d86de5ad5' `
    'TEST-0134 immutable predecessor definition blob differs.'
Assert-SequenceEqual -Actual @($catalog.Capabilities[0].Definition.requirements.id) `
    -Expected @(
        'capability-based-physical-ownership',
        'feature-based-scenario-traceability',
        'deterministic-recursive-discovery',
        'small-common-infrastructure',
        'separate-suite-processes',
        'capability-local-fixtures'
    ) -Message 'TEST-0134 test-architecture requirements differ.'

# TEST-0157: the new Semantic capability is one append-only catalog entry;
# the immutable predecessor remains the exact first entry.
Assert-Equal $catalog.Capabilities.Count 3 'TEST-0157 catalog count differs.'
Assert-Equal $catalog.Capabilities[1].Slug 'test-runtime-efficiency' `
    'TEST-0157 appended capability slug differs.'
Assert-Equal $catalog.Capabilities[1].Type 'Semantic' `
    'TEST-0157 appended capability type differs.'
Assert-Equal $catalog.Capabilities[1].DefinitionPath `
    'test-runtime-efficiency.json' `
    'TEST-0157 appended capability definition path differs.'
Assert-Equal $catalog.Capabilities[1].DefinitionBlob `
    '20c6bc064d04be18ede7ab70983503feb4b799ea' `
    'TEST-0157 appended definition blob differs.'
Assert-SequenceEqual -Actual @(
    $catalog.Capabilities[1].Definition.requirements.id
) -Expected @(
    'lowest-faithful-evidence-level',
    'reuse-equivalent-immutable-setup',
    'fresh-mutable-derivatives',
    'machine-readable-resource-contract',
    'fail-closed-resource-integrity',
    'reviewed-budget-deltas'
) -Message 'TEST-0157 test-runtime-efficiency requirements differ.'
Assert-Equal $catalog.Capabilities[1].Definition.applicability.condition `
    'expensive-deterministic-test-setup' `
    'TEST-0157 applicability condition differs.'
Assert-Equal @(
    $catalog.Capabilities[1].Definition.evidence.notApplicable
).Count 2 'TEST-0157 reviewed NotApplicable evidence contract differs.'
$canonicalEvidence = $catalog.Capabilities[2]
Assert-Equal $canonicalEvidence.Slug 'canonical-repository-evidence' `
    'TEST-0171 canonical repository-evidence slug differs.'
Assert-Equal $canonicalEvidence.Type 'Semantic' `
    'TEST-0171 canonical repository-evidence type differs.'
Assert-Equal $canonicalEvidence.DefinitionPath `
    'canonical-repository-evidence.json' `
    'TEST-0171 canonical repository-evidence definition path differs.'
Assert-Equal $canonicalEvidence.DefinitionBlob `
    '5a323d1cc9b5e64564f63dc577ad0c937a1c91c0' `
    'TEST-0171 canonical repository-evidence definition blob differs.'
Assert-SequenceEqual -Actual @(
    $canonicalEvidence.Definition.requirements.id
) -Expected @(
    'state-owned-byte-source',
    'exact-byte-preservation',
    'fail-closed-state-ambiguity',
    'contained-ordinary-evidence',
    'read-only-idempotent-resolution',
    'semantic-consumer-ownership'
) -Message 'TEST-0171 canonical repository-evidence requirements differ.'
$efficiencyNotApplicable = Resolve-MeAndAICapabilityAssessment `
    -Capability $catalog.Capabilities[1] -Applicability NotApplicable `
    -Conformance Unknown -EvidenceKind SemanticReview `
    -Evidence @('Reviewed repository has no repeated expensive deterministic setup.') `
    -ReviewIdentity 'github:maintainer' -AdoptionPlan NotRequired
Assert-Equal $efficiencyNotApplicable.Outcome 'NotApplicable' `
    'TEST-0157 reviewed inapplicable repository did not reach a terminal outcome.'

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) `
    ('meandai-capability-catalog-' + [guid]::NewGuid().ToString('N'))
try {
    $releasePredecessorRoot = Join-Path $fixtureRoot 'release-predecessor'
    [IO.Directory]::CreateDirectory($releasePredecessorRoot) | Out-Null
    [IO.File]::Copy(
        (Join-Path $root 'capabilities/test-architecture.json'),
        (Join-Path $releasePredecessorRoot 'test-architecture.json')
    )
    $releasePredecessorIndex = [ordered]@{
        schema = 1
        capabilities = @(
            [ordered]@{
                slug = 'test-architecture'
                definition = 'test-architecture.json'
                type = 'Semantic'
                definitionBlob =
                    '9a3a999f05abbbb4ee710f14d82fb26d86de5ad5'
            }
        )
    }
    $releasePredecessorIndexPath = Join-Path $releasePredecessorRoot 'index.json'
    [IO.File]::WriteAllBytes(
        $releasePredecessorIndexPath,
        (ConvertTo-TestJsonBytes -Value $releasePredecessorIndex)
    )
    $releasePredecessor = Import-MeAndAICapabilityCatalog `
        -IndexPath $releasePredecessorIndexPath
    Assert-MeAndAICapabilityCatalogExtension `
        -CurrentCatalog $releasePredecessor -TargetCatalog $catalog

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
    Assert-Equal $ledger.Entries[0].ReviewedAt '2026-07-19T10:20:30Z' `
        'TEST-0134 canonical review timestamp did not survive ledger import.'
    $terminalPending = @(Get-MeAndAICapabilityPending -Catalog $catalog `
        -LedgerBytes $ledgerBytes)
    Assert-Equal $terminalPending.Count 2 `
        'TEST-0171 one-entry predecessor did not expose both appended capabilities.'
    Assert-SequenceEqual -Actual @($terminalPending.Slug) -Expected @(
        'test-runtime-efficiency',
        'canonical-repository-evidence'
    ) -Message 'TEST-0171 one-entry predecessor capability order differs.'

    $appendedEntry = New-ReviewedEntry -Catalog $catalog -CapabilityIndex 1
    $completeLedgerBytes = ConvertTo-MeAndAICapabilityLedgerBytes `
        -Catalog $catalog -Entries @($entry, $appendedEntry)
    $completePending = @(Get-MeAndAICapabilityPending -Catalog $catalog `
        -LedgerBytes $completeLedgerBytes)
    Assert-Equal $completePending.Count 1 `
        'TEST-0171 two-entry predecessor did not expose one appended capability.'
    Assert-Equal $completePending[0].Slug 'canonical-repository-evidence' `
        'TEST-0171 two-entry predecessor exposed the wrong capability.'
    $canonicalEvidenceEntry = New-ReviewedEntry -Catalog $catalog `
        -CapabilityIndex 2
    $terminalLedgerBytes = ConvertTo-MeAndAICapabilityLedgerBytes `
        -Catalog $catalog `
        -Entries @($entry, $appendedEntry, $canonicalEvidenceEntry)
    Assert-Equal @(Get-MeAndAICapabilityPending -Catalog $catalog `
        -LedgerBytes $terminalLedgerBytes).Count 0 `
        'TEST-0171 complete three-entry terminal ledger was not idempotent.'
    foreach ($invalidPrefix in @(
        [pscustomobject]@{
            Name = 'reordered'
            Entries = @($appendedEntry, $entry)
        },
        [pscustomobject]@{
            Name = 'duplicated'
            Entries = @($entry, $entry)
        }
    )) {
        Assert-ThrowsLike -Action {
            ConvertTo-MeAndAICapabilityLedgerBytes -Catalog $catalog `
                -Entries $invalidPrefix.Entries
        } -Pattern '*not the exact installed-catalog prefix*' `
            -Message "TEST-0157 $($invalidPrefix.Name) ledger prefix was accepted."
    }

    $missingLedger = Import-MeAndAICapabilityLedger -Catalog $catalog -Bytes $null
    Assert-True $missingLedger.Missing 'TEST-0134 missing ledger was not represented explicitly.'
    $missingPending = @(Get-MeAndAICapabilityPending -Catalog $catalog)
    Assert-Equal $missingPending.Count 3 `
        'TEST-0171 missing ledger did not expose all pending capabilities.'
    Assert-SequenceEqual -Actual @($missingPending.Slug) -Expected @(
        'test-architecture',
        'test-runtime-efficiency',
        'canonical-repository-evidence'
    ) -Message 'TEST-0171 missing-ledger capability order differs.'
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

    foreach ($timestampCase in @(
        [pscustomobject]@{
            Name = 'fractional-seconds'
            Value = '2026-07-19T10:20:30.000Z'
        },
        [pscustomobject]@{
            Name = 'explicit-zero-offset'
            Value = '2026-07-19T10:20:30+00:00'
        },
        [pscustomobject]@{
            Name = 'missing-zone'
            Value = '2026-07-19T10:20:30'
        }
    )) {
        $nonCanonicalTimestamp = $canonicalLedgerText.Replace(
            '2026-07-19T10:20:30Z',
            [string]$timestampCase.Value
        )
        Assert-ThrowsLike -Action {
            Import-MeAndAICapabilityLedger -Catalog $catalog `
                -Bytes ([Text.UTF8Encoding]::new($false).GetBytes(
                    $nonCanonicalTimestamp
                ))
        } -Pattern '*canonical*' `
            -Message "TEST-0134 noncanonical timestamp '$($timestampCase.Name)' was accepted."
    }

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

    # TEST-0171: repository evidence uses the exact canonical Git boundary
    # without normalizing bytes and fails closed for ambiguous repository state.
    $seedRoot = Join-Path $fixtureRoot 'repository-evidence-seed'
    Initialize-TestGitRepository -Directory $seedRoot
    $trackedRelative = 'tracked-ledger.json'
    $seedTrackedPath = Join-Path $seedRoot $trackedRelative
    [IO.File]::WriteAllBytes($seedTrackedPath, $ledgerBytes)
    [void](Invoke-TestGit -Repository $seedRoot -Arguments @(
        'add', '--', $trackedRelative
    ))
    [void](Invoke-TestGit -Repository $seedRoot -Arguments @(
        'commit', '--quiet', '-m', 'canonical LF ledger'
    ))
    Assert-True (-not (Test-Path -LiteralPath (
        Join-Path $seedRoot '.gitattributes'
    ))) 'TEST-0171 seed unexpectedly contains a .gitattributes rule.'
    $evidenceRoot = Join-Path $fixtureRoot 'repository-evidence-consumer'
    [void](Invoke-TestGit -Repository $fixtureRoot -Arguments @(
        '-c', 'core.autocrlf=true',
        'clone', '--quiet', '--local',
        './repository-evidence-seed',
        'repository-evidence-consumer'
    ))
    [void](Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'config', 'core.autocrlf', 'true'
    ))
    [void](Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'config', 'commit.gpgsign', 'false'
    ))
    $trackedPath = Join-Path $evidenceRoot $trackedRelative
    $evidenceHead = (Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'rev-parse', 'HEAD'
    )).Text
    $transformedWorktreeBytes = [IO.File]::ReadAllBytes($trackedPath)
    Assert-True ($transformedWorktreeBytes -contains [byte]13) `
        'TEST-0171 fresh autocrlf checkout did not expose transformed worktree bytes.'
    Assert-Equal (Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'status', '--porcelain=v1', '--', $trackedRelative
    )).Text '' 'TEST-0171 transformed checkout was not Git-clean.'
    $cleanEvidence = Get-MeAndAIRepositoryEvidence `
        -RepositoryRoot $evidenceRoot -RelativePath $trackedRelative `
        -Head $evidenceHead
    Assert-Equal $cleanEvidence.Source 'Head' `
        'TEST-0171 clean tracked evidence did not identify the requested HEAD.'
    Assert-BytesEqual -Actual $cleanEvidence.Bytes -Expected $ledgerBytes `
        -Message 'TEST-0171 clean state returned transformed worktree bytes.'
    [void](Import-MeAndAICapabilityLedger -Catalog $catalog `
        -Bytes ([byte[]]$cleanEvidence.Bytes))
    Assert-ThrowsLike -Action {
        Import-MeAndAICapabilityLedger -Catalog $catalog `
            -Bytes $transformedWorktreeBytes
    } -Pattern '*must use LF line endings*' `
        -Message 'TEST-0171 strict parser accepted transformed CRLF worktree bytes.'
    Assert-TestRepositoryEvidenceRerun -Repository $evidenceRoot `
        -RelativePath $trackedRelative -Head $evidenceHead `
        -ExpectedSource Head -ExpectedBytes $ledgerBytes `
        -Message 'TEST-0171 clean HEAD rerun'

    $stagedBytes = [Text.UTF8Encoding]::new($false).GetBytes(
        '{"staged":true}' + "`n"
    )
    [IO.File]::WriteAllBytes($trackedPath, $stagedBytes)
    [void](Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'add', '--', $trackedRelative
    ))
    $stagedEvidence = Get-MeAndAIRepositoryEvidence `
        -RepositoryRoot $evidenceRoot -RelativePath $trackedRelative `
        -Head $evidenceHead
    Assert-Equal $stagedEvidence.Source 'Index' `
        'TEST-0171 staged-only evidence did not identify the stage-zero index.'
    Assert-BytesEqual -Actual $stagedEvidence.Bytes -Expected $stagedBytes `
        -Message 'TEST-0171 staged-only evidence did not preserve index bytes.'
    Assert-TestRepositoryEvidenceRerun -Repository $evidenceRoot `
        -RelativePath $trackedRelative -Head $evidenceHead `
        -ExpectedSource Index -ExpectedBytes $stagedBytes `
        -Message 'TEST-0171 stage-zero index rerun'
    [IO.File]::WriteAllBytes(
        $trackedPath,
        [Text.UTF8Encoding]::new($false).GetBytes('{"unstaged":true}' + "`n")
    )
    Assert-ThrowsLike -Action {
        Get-MeAndAIRepositoryEvidence -RepositoryRoot $evidenceRoot `
            -RelativePath $trackedRelative -Head $evidenceHead
    } -Pattern '*staged and unstaged*' `
        -Message 'TEST-0171 staged-plus-unstaged state did not fail closed.'

    [void](Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'reset', '--hard', '--quiet', $evidenceHead
    ))
    $rawDriftBytes = [Text.UTF8Encoding]::new($false).GetBytes(
        '{"real-drift":true}' + "`r`n"
    )
    [IO.File]::WriteAllBytes($trackedPath, $rawDriftBytes)
    $unstagedEvidence = Get-MeAndAIRepositoryEvidence `
        -RepositoryRoot $evidenceRoot -RelativePath $trackedRelative `
        -Head $evidenceHead
    Assert-Equal $unstagedEvidence.Source 'Worktree' `
        'TEST-0171 unstaged evidence did not identify the worktree.'
    Assert-BytesEqual -Actual $unstagedEvidence.Bytes -Expected $rawDriftBytes `
        -Message 'TEST-0171 unstaged evidence normalized raw worktree bytes.'
    Assert-TestRepositoryEvidenceRerun -Repository $evidenceRoot `
        -RelativePath $trackedRelative -Head $evidenceHead `
        -ExpectedSource Worktree -ExpectedBytes $rawDriftBytes `
        -Message 'TEST-0171 tracked worktree rerun'
    Assert-ThrowsLike -Action {
        Import-MeAndAICapabilityLedger -Catalog $catalog `
            -Bytes ([byte[]]$unstagedEvidence.Bytes)
    } -Pattern '*must use LF line endings*' `
        -Message 'TEST-0171 genuine CRLF drift was normalized before strict parsing.'

    [void](Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'reset', '--hard', '--quiet', $evidenceHead
    ))
    $untrackedRelative = 'untracked-evidence.json'
    $untrackedBytes = [byte[]](0x00, 0x0D, 0x0A, 0xFF)
    [IO.File]::WriteAllBytes(
        (Join-Path $evidenceRoot $untrackedRelative),
        $untrackedBytes
    )
    $untrackedEvidence = Get-MeAndAIRepositoryEvidence `
        -RepositoryRoot $evidenceRoot -RelativePath $untrackedRelative `
        -Head $evidenceHead
    Assert-Equal $untrackedEvidence.Source 'Worktree' `
        'TEST-0171 untracked evidence did not identify the worktree.'
    Assert-BytesEqual -Actual $untrackedEvidence.Bytes -Expected $untrackedBytes `
        -Message 'TEST-0171 untracked evidence normalized raw worktree bytes.'
    Assert-TestRepositoryEvidenceRerun -Repository $evidenceRoot `
        -RelativePath $untrackedRelative -Head $evidenceHead `
        -ExpectedSource Worktree -ExpectedBytes $untrackedBytes `
        -Message 'TEST-0171 untracked worktree rerun'
    $missingEvidence = Get-MeAndAIRepositoryEvidence `
        -RepositoryRoot $evidenceRoot -RelativePath 'optional-missing.json' `
        -Head $evidenceHead
    Assert-Equal $missingEvidence.Source 'Missing' `
        'TEST-0171 clean optional absence did not resolve as Missing.'
    Assert-True ($null -eq $missingEvidence.Bytes) `
        'TEST-0171 clean optional absence returned bytes.'

    [void](Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'rm', '--quiet', '--', $trackedRelative
    ))
    Assert-ThrowsLike -Action {
        Get-MeAndAIRepositoryEvidence -RepositoryRoot $evidenceRoot `
            -RelativePath $trackedRelative -Head $evidenceHead
    } -Pattern '*deletion*' `
        -Message 'TEST-0171 staged deletion did not fail closed.'
    [void](Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'reset', '--hard', '--quiet', $evidenceHead
    ))

    $renamedRelative = 'renamed-evidence.json'
    [void](Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'mv', $trackedRelative, $renamedRelative
    ))
    Assert-ThrowsLike -Action {
        Get-MeAndAIRepositoryEvidence -RepositoryRoot $evidenceRoot `
            -RelativePath $renamedRelative -Head $evidenceHead
    } -Pattern '*rename or copy*' `
        -Message 'TEST-0171 staged rename did not fail closed.'
    [void](Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'reset', '--hard', '--quiet', $evidenceHead
    ))

    $copyRelative = 'copied-evidence.json'
    [IO.File]::Copy($trackedPath, (Join-Path $evidenceRoot $copyRelative))
    [void](Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'add', '--', $copyRelative
    ))
    $copyIndexBlob = (Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'rev-parse', ":$copyRelative"
    )).Text
    $copyHeadBlob = (Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'rev-parse', "${evidenceHead}:$trackedRelative"
    )).Text
    Assert-Equal $copyIndexBlob $copyHeadBlob `
        'TEST-0171 exact staged-copy blob precondition differs.'
    Assert-ThrowsLike -Action {
        Get-MeAndAIRepositoryEvidence -RepositoryRoot $evidenceRoot `
            -RelativePath $copyRelative -Head $evidenceHead
    } -Pattern '*rename or copy*' `
        -Message 'TEST-0171 staged copy did not fail closed.'
    [void](Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'reset', '--hard', '--quiet', $evidenceHead
    ))
    [IO.File]::Delete((Join-Path $evidenceRoot $copyRelative))

    $linkRelative = 'linked-evidence.json'
    $linkTargetPath = Join-Path $evidenceRoot 'link-target.txt'
    [IO.File]::WriteAllText($linkTargetPath, 'tracked-ledger.json')
    $linkBlob = (Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'hash-object', '-w', '--', $linkTargetPath
    )).Text
    [void](Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'update-index', '--add', '--cacheinfo',
        "120000,$linkBlob,$linkRelative"
    ))
    Assert-ThrowsLike -Action {
        Get-MeAndAIRepositoryEvidence -RepositoryRoot $evidenceRoot `
            -RelativePath $linkRelative -Head $evidenceHead
    } -Pattern '*regular blob*' `
        -Message 'TEST-0171 staged link did not fail closed.'
    [void](Invoke-TestGit -Repository $evidenceRoot -Arguments @(
        'reset', '--hard', '--quiet', $evidenceHead
    ))

    $conflictRoot = Join-Path $fixtureRoot 'repository-evidence-conflict'
    Initialize-TestGitRepository -Directory $conflictRoot
    $conflictRelative = 'conflicted.json'
    $conflictPath = Join-Path $conflictRoot $conflictRelative
    [IO.File]::WriteAllText($conflictPath, "base`n")
    [void](Invoke-TestGit -Repository $conflictRoot -Arguments @(
        'add', '--', $conflictRelative
    ))
    [void](Invoke-TestGit -Repository $conflictRoot -Arguments @(
        'commit', '--quiet', '-m', 'conflict base'
    ))
    $conflictBase = (Invoke-TestGit -Repository $conflictRoot -Arguments @(
        'rev-parse', 'HEAD'
    )).Text
    [void](Invoke-TestGit -Repository $conflictRoot -Arguments @(
        'checkout', '--quiet', '-b', 'other'
    ))
    [IO.File]::WriteAllText($conflictPath, "other`n")
    [void](Invoke-TestGit -Repository $conflictRoot -Arguments @(
        'commit', '--quiet', '-am', 'other side'
    ))
    [void](Invoke-TestGit -Repository $conflictRoot -Arguments @(
        'checkout', '--quiet', '-b', 'current', $conflictBase
    ))
    [IO.File]::WriteAllText($conflictPath, "current`n")
    [void](Invoke-TestGit -Repository $conflictRoot -Arguments @(
        'commit', '--quiet', '-am', 'current side'
    ))
    $conflictHead = (Invoke-TestGit -Repository $conflictRoot -Arguments @(
        'rev-parse', 'HEAD'
    )).Text
    [void](Invoke-TestGit -Repository $conflictRoot -Arguments @(
        'merge', 'other'
    ) -AllowedExitCodes @(1))
    Assert-ThrowsLike -Action {
        Get-MeAndAIRepositoryEvidence -RepositoryRoot $conflictRoot `
            -RelativePath $conflictRelative -Head $conflictHead
    } -Pattern '*conflicted*' `
        -Message 'TEST-0171 conflicted index did not fail closed.'

    Assert-ThrowsLike -Action {
        Get-MeAndAIRepositoryEvidence -RepositoryRoot $evidenceRoot `
            -RelativePath '../escaped.json' -Head $evidenceHead
    } -Pattern '*canonical repository-relative path*' `
        -Message 'TEST-0171 escaping path did not fail closed.'
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
