$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$owner = 'tests/capabilities/consumer-update/consumer-migrations.tests.ps1'
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
$contentIdentityModule = Import-Module `
    (Join-Path $root 'scripts/MeAndAI.ContentIdentity.psm1') -Force -PassThru
$testByteArrayEqualAction = $contentIdentityModule.ExportedCommands[
    'Test-MeAndAIByteArrayEqual'
].ScriptBlock
Import-Module (Join-Path $root 'scripts/MeAndAI.ConsumerMigrations.psm1') -Force
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.TestAssertions.psm1') -Force
$scenarioEvidenceContext = New-MeAndAIScenarioEvidenceContext `
    -Owner $owner -AuthorityPath $scenarioAuthorityPath

function ConvertTo-TestBytes {
    param([string]$Text, [ValidateSet('LF', 'CRLF')][string]$LineEnding, [bool]$Bom)

    $formatted = if ($LineEnding -ceq 'CRLF') {
        $Text.Replace("`r`n", "`n").Replace("`n", "`r`n")
    }
    else { $Text.Replace("`r`n", "`n") }
    $body = [Text.UTF8Encoding]::new($false).GetBytes($formatted)
    if (-not $Bom) { return $body }
    $bytes = [byte[]]::new($body.Length + 3)
    $bytes[0] = 0xEF; $bytes[1] = 0xBB; $bytes[2] = 0xBF
    [Array]::Copy($body, 0, $bytes, 3, $body.Length)
    return $bytes
}

function ConvertFrom-TestBytes {
    param([byte[]]$Bytes)

    $offset = if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and
        $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) { 3 } else { 0 }
    return [Text.UTF8Encoding]::new($false, $true).GetString(
        $Bytes, $offset, $Bytes.Length - $offset
    )
}

function New-Mig0001Files {
    param($Catalog, [ValidateSet('Before', 'After')][string]$State)

    $records = [System.Collections.Generic.List[object]]::new()
    $formats = [System.Collections.Generic.Dictionary[string,object]]::new(
        [StringComparer]::Ordinal
    )
    $index = 0
    foreach ($operation in @($Catalog.Migrations[0].Operations)) {
        $fragment = if ($State -ceq 'Before') {
            [string]$operation.Before
        }
        else { [string]$operation.After }
        $lineEnding = if (($index % 2) -eq 0) { 'LF' } else { 'CRLF' }
        $bom = ($index % 3) -eq 0
        $text = "consumer prefix for $($operation.Path)`n$fragment`nconsumer-owned tail`n"
        $bytes = ConvertTo-TestBytes -Text $text -LineEnding $lineEnding -Bom $bom
        $records.Add([pscustomobject][ordered]@{
            Path = [string]$operation.Path
            Bytes = [byte[]]$bytes
        })
        $formats.Add([string]$operation.Path, [pscustomobject]@{
            LineEnding = $lineEnding
            Bom = $bom
            Original = [byte[]]$bytes.Clone()
        })
        $index++
    }
    return [pscustomobject]@{ Records = @($records); Formats = $formats }
}

function Copy-FileRecords {
    param([object[]]$Records)
    return @($Records | ForEach-Object {
        [pscustomobject][ordered]@{
            Path = [string]$_.Path
            Bytes = [byte[]]([byte[]]$_.Bytes).Clone()
        }
    })
}

$catalog = Import-MeAndAIConsumerMigrationCatalog `
    -IndexPath (Join-Path $root 'migrations/index.json')
Assert-Equal $catalog.Schema 1 'Catalog schema differs.'
Assert-Equal $catalog.Migrations.Count 1 'Catalog migration count differs.'
Assert-Equal $catalog.Migrations[0].Id 'MIG-0001' 'First migration identity differs.'
Assert-Equal $catalog.Migrations[0].Operations.Count 8 'MIG-0001 must contain eight exact operations.'
Assert-True ($catalog.Migrations[0].PSObject.Properties.Name -cnotcontains 'SourceVersion') `
    'Migration definitions must not encode a source-version condition.'
Assert-True ([string]$catalog.Migrations[0].DefinitionBlob -cmatch '^[0-9a-f]{40}$') `
    'Definition evidence is not one exact Git blob SHA.'

# The same repository state produces the same plan regardless of whether the
# caller discovered it while simulating v0.9.2 or v0.10.2. Source versions are
# intentionally outside the pure migration contract.
$legacyFixture = New-Mig0001Files -Catalog $catalog -State Before
$legacySnapshots = Copy-FileRecords -Records $legacyFixture.Records
$plansBySimulatedSource = @{}
foreach ($simulatedSource in @('v0.9.2', 'v0.10.2')) {
    $plansBySimulatedSource[$simulatedSource] = Resolve-MeAndAIConsumerMigrationPlan `
        -Catalog $catalog -Files (Copy-FileRecords -Records $legacyFixture.Records)
}
$legacyPlan = $plansBySimulatedSource['v0.9.2']
Assert-Equal $legacyPlan.State 'ChangesRequired' 'Legacy state was not planned.'
Assert-Equal $legacyPlan.Migrations.Count 1 'Legacy migration evidence count differs.'
Assert-Equal $legacyPlan.Migrations[0].State 'Applied' 'Legacy migration was not applied in memory.'
Assert-Equal $legacyPlan.ExpectedChangedPaths.Count 9 `
    'Legacy plan must change eight consumer paths and one ledger.'
Assert-Equal $plansBySimulatedSource['v0.10.2'].PlanSha256 $legacyPlan.PlanSha256 `
    'State-identical simulations produced different plans.'
Assert-True ($legacyPlan.PlanSha256 -cmatch '^[0-9a-f]{64}$') `
    'Plan evidence is not one deterministic SHA-256.'

$expectedChanged = [string[]](@('.ai/meandai-update-state.json') + @(
    $catalog.Migrations[0].Operations | ForEach-Object { [string]$_.Path }
))
[Array]::Sort($expectedChanged, [StringComparer]::Ordinal)
Assert-SequenceEqual -Actual @($legacyPlan.ExpectedChangedPaths) `
    -Expected $expectedChanged -Message 'Legacy changed-path evidence differs.'

foreach ($snapshot in $legacySnapshots) {
    $current = @($legacyFixture.Records | Where-Object {
        [string]$_.Path -ceq [string]$snapshot.Path
    })[0]
    Assert-True (& $testByteArrayEqualAction `
        -Left ([byte[]]$snapshot.Bytes) -Right ([byte[]]$current.Bytes)) `
        "Planner mutated caller bytes for '$($snapshot.Path)'."
}

foreach ($pathResult in @($legacyPlan.Paths)) {
    $operation = @($catalog.Migrations[0].Operations | Where-Object {
        [string]$_.Path -ceq [string]$pathResult.Path
    })[0]
    $format = $legacyFixture.Formats[[string]$pathResult.Path]
    $resultBytes = [byte[]]$pathResult.ResultBytes
    $hasBom = $resultBytes.Length -ge 3 -and $resultBytes[0] -eq 0xEF -and
        $resultBytes[1] -eq 0xBB -and $resultBytes[2] -eq 0xBF
    Assert-Equal $hasBom ([bool]$format.Bom) `
        "BOM state changed for '$($pathResult.Path)'."
    $text = ConvertFrom-TestBytes -Bytes $resultBytes
    if ([string]$format.LineEnding -ceq 'CRLF') {
        Assert-True ($text.Contains("`r`n") -and -not $text.Replace("`r`n", '').Contains("`n")) `
            "CRLF style changed for '$($pathResult.Path)'."
    }
    else {
        Assert-True (-not $text.Contains("`r") -and $text.Contains("`n")) `
            "LF style changed for '$($pathResult.Path)'."
    }
    $normalized = $text.Replace("`r`n", "`n")
    Assert-True ($normalized.Contains([string]$operation.After)) `
        "Replacement is absent for '$($pathResult.Path)'."
    Assert-True (-not $normalized.Contains([string]$operation.Before)) `
        "Legacy fragment remains for '$($pathResult.Path)'."
    Assert-True ($normalized.Contains('consumer-owned tail')) `
        "Consumer content was not preserved for '$($pathResult.Path)'."
    Assert-True ([string]$pathResult.OriginalBlob -cmatch '^[0-9a-f]{40}$' -and
        [string]$pathResult.ResultBlob -cmatch '^[0-9a-f]{40}$') `
        "Path blob evidence is invalid for '$($pathResult.Path)'."
}

$reversePlan = Resolve-MeAndAIConsumerMigrationPlan -Catalog $catalog `
    -Files @($legacyFixture.Records | Sort-Object Path -Descending)
Assert-Equal $reversePlan.PlanSha256 $legacyPlan.PlanSha256 `
    'Input record order changed deterministic plan evidence.'

$neutralFixture = New-Mig0001Files -Catalog $catalog -State After
$neutralPlan = Resolve-MeAndAIConsumerMigrationPlan -Catalog $catalog `
    -Files $neutralFixture.Records
Assert-Equal $neutralPlan.Migrations[0].State 'AlreadySatisfied' `
    'Neutral state was not recognized.'
Assert-SequenceEqual -Actual @($neutralPlan.ExpectedChangedPaths) `
    -Expected @('.ai/meandai-update-state.json') `
    -Message 'Neutral bootstrap must add only the ledger.'
Assert-True (@($neutralPlan.Paths | Where-Object Changed).Count -eq 0) `
    'Neutral consumer paths were unexpectedly changed.'

$baseline = New-MeAndAIConsumerMigrationBaseline -Catalog $catalog
Assert-True ($baseline.Bytes -is [byte[]]) 'Baseline ledger bytes are not a byte array.'
$requiredWithoutLedger = @(Get-MeAndAIConsumerMigrationRequiredPaths `
    -Catalog $catalog)
Assert-Equal $requiredWithoutLedger.Count 8 `
    'Missing-ledger required-path inventory differs.'
$requiredWithLedger = @(Get-MeAndAIConsumerMigrationRequiredPaths `
    -Catalog $catalog -LedgerBytes ([byte[]]$baseline.Bytes))
Assert-Equal $requiredWithLedger.Count 0 `
    'Satisfied ledger retained pending migration paths.'
Assert-MeAndAIConsumerMigrationCatalogExtension -CurrentCatalog $catalog `
    -TargetCatalog $catalog
$satisfiedPlan = Resolve-MeAndAIConsumerMigrationPlan -Catalog $catalog `
    -Files @() -LedgerBytes ([byte[]]$baseline.Bytes)
Assert-Equal $satisfiedPlan.State 'Satisfied' 'Canonical baseline was not idempotent.'
Assert-Equal $satisfiedPlan.ExpectedChangedPaths.Count 0 `
    'Canonical baseline produced an unexpected change.'
Confirm-MeAndAIScenarioEvidence -Context $scenarioEvidenceContext `
    -TestId 'TEST-0119'

# Two generic migrations may form an ordered chain on the same consumer path.
$chainRoot = Join-Path ([IO.Path]::GetTempPath()) ("meandai-migration-chain-" + [guid]::NewGuid().ToString('N'))
try {
    [IO.Directory]::CreateDirectory($chainRoot) | Out-Null
    [IO.File]::WriteAllText((Join-Path $chainRoot 'index.json'), @'
{"schema":1,"migrations":[{"id":"MIG-9001","introducedIn":"v0.10.3","definition":"MIG-9001.json"},{"id":"MIG-9002","introducedIn":"v0.10.4","definition":"MIG-9002.json"}]}
'@.TrimStart(), [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $chainRoot 'MIG-9001.json'), @'
{"schema":1,"id":"MIG-9001","operations":[{"kind":"replace-exactly-once","path":"consumer.txt","before":["ALPHA"],"after":["BETA"]}]}
'@.TrimStart(), [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $chainRoot 'MIG-9002.json'), @'
{"schema":1,"id":"MIG-9002","operations":[{"kind":"replace-exactly-once","path":"consumer.txt","before":["BETA"],"after":["GAMMA"]}]}
'@.TrimStart(), [Text.UTF8Encoding]::new($false))
    $chainCatalog = Import-MeAndAIConsumerMigrationCatalog `
        -IndexPath (Join-Path $chainRoot 'index.json')

    $currentChainRoot = Join-Path $chainRoot 'current'
    [IO.Directory]::CreateDirectory($currentChainRoot) | Out-Null
    [IO.File]::WriteAllText((Join-Path $currentChainRoot 'index.json'), @'
{"schema":1,"migrations":[{"id":"MIG-9001","introducedIn":"v0.10.3","definition":"MIG-9001.json"}]}
'@.TrimStart(), [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllBytes(
        (Join-Path $currentChainRoot 'MIG-9001.json'),
        [IO.File]::ReadAllBytes((Join-Path $chainRoot 'MIG-9001.json'))
    )
    $currentChainCatalog = Import-MeAndAIConsumerMigrationCatalog `
        -IndexPath (Join-Path $currentChainRoot 'index.json')
    Assert-MeAndAIConsumerMigrationCatalogExtension `
        -CurrentCatalog $currentChainCatalog -TargetCatalog $chainCatalog

    $chainFile = [pscustomobject][ordered]@{
        Path = 'consumer.txt'
        Bytes = [Text.UTF8Encoding]::new($false).GetBytes("prefix`nALPHA`suffix`n")
    }
    $chainPlan = Resolve-MeAndAIConsumerMigrationPlan -Catalog $chainCatalog `
        -Files @($chainFile)
    Assert-SequenceEqual -Actual @($chainPlan.Migrations | ForEach-Object State) `
        -Expected @('Applied', 'Applied') -Message 'Migration chain order differs.'
    Assert-True ((ConvertFrom-TestBytes -Bytes ([byte[]]$chainPlan.Paths[0].ResultBytes)).Contains('GAMMA')) `
        'Migration chain did not produce the final state.'
    Assert-True (-not (ConvertFrom-TestBytes -Bytes ([byte[]]$chainPlan.Paths[0].ResultBytes)).Contains('ALPHA')) `
        'Migration chain retained the initial state.'

    $currentChainBaseline = New-MeAndAIConsumerMigrationBaseline `
        -Catalog $currentChainCatalog
    $suffixPaths = @(Get-MeAndAIConsumerMigrationRequiredPaths `
        -Catalog $chainCatalog -LedgerBytes ([byte[]]$currentChainBaseline.Bytes))
    Assert-SequenceEqual -Actual $suffixPaths -Expected @('consumer.txt') `
        -Message 'Target suffix required-path inventory differs.'
    $suffixFile = [pscustomobject][ordered]@{
        Path = 'consumer.txt'
        Bytes = [Text.UTF8Encoding]::new($false).GetBytes("prefix`nBETA`suffix`n")
    }
    $suffixPlan = Resolve-MeAndAIConsumerMigrationPlan -Catalog $chainCatalog `
        -LedgerBytes ([byte[]]$currentChainBaseline.Bytes) -Files @($suffixFile)
    Assert-Equal $suffixPlan.Migrations.Count 1 `
        'Current ledger did not select exactly the target-catalog suffix.'
    Assert-Equal $suffixPlan.Migrations[0].Id 'MIG-9002' `
        'Wrong target-catalog suffix migration was selected.'

    Assert-ThrowsLike -Action {
        Assert-MeAndAIConsumerMigrationCatalogExtension `
            -CurrentCatalog $catalog -TargetCatalog $chainCatalog
    } -Pattern '*changes installed prefix entry*' `
        -Message 'A rewritten catalog prefix did not fail closed.'

    # Every compatible descendant must extend the immediately preceding
    # catalog. Comparing only vA with a skipped vC would miss a migration that
    # vB introduced and vC later removed or rewrote.
    $appendRoot = Join-Path $chainRoot 'append'
    [IO.Directory]::CreateDirectory($appendRoot) | Out-Null
    [IO.File]::WriteAllText((Join-Path $appendRoot 'index.json'), @'
{"schema":1,"migrations":[{"id":"MIG-9001","introducedIn":"v0.10.3","definition":"MIG-9001.json"},{"id":"MIG-9002","introducedIn":"v0.10.4","definition":"MIG-9002.json"},{"id":"MIG-9003","introducedIn":"v0.10.5","definition":"MIG-9003.json"}]}
'@.TrimStart(), [Text.UTF8Encoding]::new($false))
    foreach ($definition in @('MIG-9001.json', 'MIG-9002.json')) {
        [IO.File]::WriteAllBytes(
            (Join-Path $appendRoot $definition),
            [IO.File]::ReadAllBytes((Join-Path $chainRoot $definition))
        )
    }
    [IO.File]::WriteAllText((Join-Path $appendRoot 'MIG-9003.json'), @'
{"schema":1,"id":"MIG-9003","operations":[{"kind":"replace-exactly-once","path":"consumer.txt","before":["GAMMA"],"after":["DELTA"]}]}
'@.TrimStart(), [Text.UTF8Encoding]::new($false))
    $appendCatalog = Import-MeAndAIConsumerMigrationCatalog `
        -IndexPath (Join-Path $appendRoot 'index.json')
    Assert-MeAndAIConsumerMigrationCatalogChain -Catalogs @(
        $currentChainCatalog, $chainCatalog, $appendCatalog
    )

    Assert-ThrowsLike -Action {
        Assert-MeAndAIConsumerMigrationCatalogChain -Catalogs @(
            $currentChainCatalog, $chainCatalog, $currentChainCatalog
        )
    } -Pattern '*removes installed migration definitions*' `
        -Message 'A skipped compatible release removed an intermediate migration without failing closed.'

    $rewriteRoot = Join-Path $chainRoot 'rewrite'
    [IO.Directory]::CreateDirectory($rewriteRoot) | Out-Null
    [IO.File]::WriteAllText((Join-Path $rewriteRoot 'index.json'), @'
{"schema":1,"migrations":[{"id":"MIG-9001","introducedIn":"v0.10.3","definition":"MIG-9001.json"},{"id":"MIG-9002","introducedIn":"v0.10.4","definition":"MIG-9002.json"}]}
'@.TrimStart(), [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllBytes(
        (Join-Path $rewriteRoot 'MIG-9001.json'),
        [IO.File]::ReadAllBytes((Join-Path $chainRoot 'MIG-9001.json'))
    )
    [IO.File]::WriteAllText((Join-Path $rewriteRoot 'MIG-9002.json'), @'
{"schema":1,"id":"MIG-9002","operations":[{"kind":"replace-exactly-once","path":"consumer.txt","before":["BETA"],"after":["REWRITTEN"]}]}
'@.TrimStart(), [Text.UTF8Encoding]::new($false))
    $rewriteCatalog = Import-MeAndAIConsumerMigrationCatalog `
        -IndexPath (Join-Path $rewriteRoot 'index.json')
    Assert-ThrowsLike -Action {
        Assert-MeAndAIConsumerMigrationCatalogChain -Catalogs @(
            $currentChainCatalog, $chainCatalog, $rewriteCatalog
        )
    } -Pattern "*changes installed prefix entry 'MIG-9002'*" `
        -Message 'A skipped compatible release rewrote an intermediate migration without failing closed.'
}
finally {
    if (Test-Path -LiteralPath $chainRoot) {
        Remove-Item -LiteralPath $chainRoot -Recurse -Force
    }
}

$driftFiles = Copy-FileRecords -Records $legacyFixture.Records
$driftOperation = $catalog.Migrations[0].Operations[0]
$driftText = (ConvertFrom-TestBytes -Bytes ([byte[]]$driftFiles[0].Bytes)).Replace(
    [string]$driftOperation.Before, 'unrecognized consumer drift'
)
$driftFiles[0].Bytes = [byte[]](ConvertTo-TestBytes -Text $driftText `
    -LineEnding 'LF' -Bom $false)
Assert-ThrowsLike -Action {
    Resolve-MeAndAIConsumerMigrationPlan -Catalog $catalog -Files $driftFiles
} -Pattern "*path 'AGENTS.md' is unsupported*" `
    -Message 'Unrecognized drift did not fail closed.'

$mixedFiles = Copy-FileRecords -Records $legacyFixture.Records
$mixedOperation = $catalog.Migrations[0].Operations[1]
$mixedText = (ConvertFrom-TestBytes -Bytes ([byte[]]$mixedFiles[1].Bytes)).Replace(
    [string]$mixedOperation.Before, [string]$mixedOperation.After
)
$mixedFiles[1].Bytes = [byte[]](ConvertTo-TestBytes -Text $mixedText `
    -LineEnding 'CRLF' -Bom $false)
Assert-ThrowsLike -Action {
    Resolve-MeAndAIConsumerMigrationPlan -Catalog $catalog -Files $mixedFiles
} -Pattern "*MIG-0001*partial*" -Message 'Mixed migration state did not fail closed.'

$duplicateFiles = Copy-FileRecords -Records $legacyFixture.Records
$duplicateOperation = $catalog.Migrations[0].Operations[0]
$duplicateText = (ConvertFrom-TestBytes -Bytes ([byte[]]$duplicateFiles[0].Bytes)) +
    "`n$($duplicateOperation.Before)`n"
$duplicateFiles[0].Bytes = [byte[]](ConvertTo-TestBytes -Text $duplicateText `
    -LineEnding 'LF' -Bom $false)
Assert-ThrowsLike -Action {
    Resolve-MeAndAIConsumerMigrationPlan -Catalog $catalog -Files $duplicateFiles
} -Pattern '*before=2 after=0*' -Message 'Duplicate fragment did not fail closed.'

$driftedLedgerText = ([Text.UTF8Encoding]::new($false).GetString([byte[]]$baseline.Bytes)).Replace(
    [string]$catalog.Migrations[0].DefinitionBlob,
    ('0' * 40)
)
$driftedLedgerBytes = [Text.UTF8Encoding]::new($false).GetBytes($driftedLedgerText)
Assert-ThrowsLike -Action {
    Resolve-MeAndAIConsumerMigrationPlan -Catalog $catalog -Files @() `
        -LedgerBytes $driftedLedgerBytes
} -Pattern '*not the exact installed-catalog prefix*' `
    -Message 'Drifted ledger did not fail closed.'

Confirm-MeAndAIScenarioEvidence -Context $scenarioEvidenceContext `
    -TestId 'TEST-0120'
Write-Host 'Consumer migration tests passed.'
$scenarioResult = New-MeAndAIScenarioResult -Context $scenarioEvidenceContext
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
