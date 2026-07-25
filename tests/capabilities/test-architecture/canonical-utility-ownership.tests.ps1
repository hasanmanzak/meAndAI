[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$owner = 'tests/capabilities/test-architecture/canonical-utility-ownership.tests.ps1'
$authorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
$helperOwnershipPath = Join-Path $root 'tests/helper-ownership.psd1'
$helperOwnershipModulePath = Join-Path $root `
    'tests/infrastructure/MeAndAI.TestHelperOwnership.psm1'
$fixtureRoot = Join-Path $PSScriptRoot 'fixtures/helper-ownership'

Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.TestContext.psm1') -Force
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.TestAssertions.psm1') -Force
Import-Module $helperOwnershipModulePath -Force
Import-Module (Join-Path $root 'scripts/MeAndAI.ContentIdentity.psm1') -Force
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.MarkdownEvidence.psm1') -Force

$scenarioEvidenceContext = New-MeAndAIScenarioEvidenceContext `
    -Owner $owner -AuthorityPath $authorityPath
$failureContext = New-MeAndAITestContext
Set-MeAndAITestContext -Context $failureContext
$failures = $failureContext.Failures

foreach ($requiredAsset in @(
    'scripts/MeAndAI.ContentIdentity.psm1'
    'tests/helper-ownership.psd1'
    'tests/infrastructure/MeAndAI.MarkdownEvidence.psm1'
    'tests/infrastructure/MeAndAI.TestAssertions.psm1'
    'tests/infrastructure/MeAndAI.TestContext.psm1'
    'tests/infrastructure/MeAndAI.TestHelperOwnership.psm1'
    'tests/infrastructure/MeAndAI.TestRepository.psm1'
    'tests/infrastructure/MeAndAI.TestWorkspace.psm1'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $requiredAsset) -PathType Leaf)) {
        Add-Failure "TEST-0184 canonical helper asset is missing: $requiredAsset."
    }
}

$isolatedContext = New-MeAndAITestContext
Add-MeAndAITestFailure -Context $isolatedContext -Message 'isolated'
$snapshot = @(Get-MeAndAITestFailures -Context $isolatedContext)
$snapshot[0] = 'changed snapshot'
if ($isolatedContext.Failures.Count -ne 1 -or
    $isolatedContext.Failures[0] -cne 'isolated' -or
    $failureContext.Failures.Count -ne 0) {
    Add-Failure 'TEST-0184 explicit failure contexts are not isolated snapshots.'
}

$collectingContext = New-MeAndAITestContext
Assert-MeAndAITestCollectedTrue -Context $collectingContext `
    -Condition $false -Message 'collected truth'
Assert-MeAndAITestCollectedEqual -Context $collectingContext `
    -Expected 'expected' -Actual 'actual' -Message 'collected equality'
if ((@(Get-MeAndAITestFailures -Context $collectingContext) -join '|') -cne
    "collected truth|collected equality; expected 'expected', found 'actual'") {
    Add-Failure 'TEST-0184 collecting assertion behavior changed.'
}

$missingContextRejected = $false
Clear-MeAndAITestContext -Context $failureContext
try {
    try { Add-Failure 'must fail closed' }
    catch {
        $missingContextRejected = $_.Exception.Message -ceq
            'No meAndAI test context is active.'
    }
}
finally {
    Set-MeAndAITestContext -Context $failureContext
}
if (-not $missingContextRejected) {
    Add-Failure 'TEST-0184 failure collection accepted a missing active context.'
}

try {
    Assert-MeAndAITestTrue -Condition $true -Message 'unused'
    Assert-True -Condition $true -Message 'unused alias'
    Assert-MeAndAITestEqual -Actual 'exact' -Expected 'exact' -Message 'unused'
    Assert-MeAndAITestSequenceEqual -Actual @('a', 'b') `
        -Expected @('a', 'b') -Message 'unused'
    Assert-MeAndAITestThrowsLike -Action { throw 'expected detail' } `
        -Pattern 'expected*' -Message 'unused'
}
catch {
    Add-Failure "TEST-0184 fail-fast assertion success contract failed: $($_.Exception.Message)"
}

$binaryVector = [byte[]](0, 255, 1, 128)
if ((Get-MeAndAIGitBlobSha1 -Bytes ([byte[]]::new(0))) -cne
        'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391' -or
    (Get-MeAndAIGitBlobSha1 -Bytes $binaryVector) -cne
        '3b35d5a60837377c681e239029b3a0490d5fdead' -or
    (Get-MeAndAISha256 -Bytes $binaryVector) -cne
        'edc81f7e4ee358fb91e94bd9bd74079c3dcba36f40f2c8a36e7ae0567afecc8f' -or
    -not (Test-MeAndAIByteArrayEqual -Left $null -Right $null) -or
    -not (Test-MeAndAIByteArrayEqual -Left $binaryVector `
        -Right ([byte[]](0, 255, 1, 128))) -or
    (Test-MeAndAIByteArrayEqual -Left $binaryVector `
        -Right ([byte[]](0, 255, 1, 127)))) {
    Add-Failure 'TEST-0184 canonical content-identity known vectors changed.'
}

if (-not (Test-MeAndAIContainsExactDocumentTitle `
        -Text 'Evidence for TEST-0184.' -Title 'TEST-0184') -or
    (Test-MeAndAIContainsExactDocumentTitle `
        -Text 'Evidence for TEST-01840.' -Title 'TEST-0184')) {
    Add-Failure 'TEST-0184 canonical Markdown title boundary changed.'
}

$ownershipResult = Test-MeAndAITestHelperOwnership `
    -RepositoryRoot $root -ContractPath $helperOwnershipPath
if (-not $ownershipResult.Valid) {
    Add-Failure ('TEST-0184 canonical helper ownership failed: ' +
        ($ownershipResult.Violations -join '; '))
}

$syntheticRoot = Join-Path ([IO.Path]::GetTempPath()) `
    ('meandai-test-0184-' + [guid]::NewGuid().ToString('N'))
try {
    $syntheticInfrastructure = Join-Path $syntheticRoot 'tests/infrastructure'
    [IO.Directory]::CreateDirectory($syntheticInfrastructure) | Out-Null
    Copy-Item -LiteralPath (Join-Path $fixtureRoot 'owner.psm1.fixture') `
        -Destination (Join-Path $syntheticInfrastructure 'TestOwner.psm1')
    Copy-Item -LiteralPath (Join-Path $fixtureRoot 'unauthorized.ps1.fixture') `
        -Destination (Join-Path $syntheticRoot 'tests/unauthorized.ps1')
    Copy-Item -LiteralPath (Join-Path $fixtureRoot 'helper-ownership.psd1.fixture') `
        -Destination (Join-Path $syntheticRoot 'helper-ownership.psd1')

    $syntheticResult = Test-MeAndAITestHelperOwnership `
        -RepositoryRoot $syntheticRoot `
        -ContractPath (Join-Path $syntheticRoot 'helper-ownership.psd1')
    $expectedPrefix =
        "Guarded helper 'Add-Failure' is redefined without authority at 'tests/unauthorized.ps1:"
    if ($syntheticResult.Valid -or
        @($syntheticResult.Violations | Where-Object {
            $_.StartsWith($expectedPrefix, [StringComparison]::Ordinal)
        }).Count -ne 1) {
        Add-Failure ('TEST-0184 isolated ownership fixture was not rejected: ' +
            ($syntheticResult.Violations -join '; '))
    }
}
catch {
    Add-Failure "TEST-0184 isolated ownership fixture failed: $($_.Exception.Message)"
}
finally {
    if (Test-Path -LiteralPath $syntheticRoot) {
        Remove-Item -LiteralPath $syntheticRoot -Recurse -Force
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Helper ownership validation failed with $($failures.Count) problem(s):" `
        -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Confirm-MeAndAIScenarioEvidence -Context $scenarioEvidenceContext `
    -TestId 'TEST-0184'
$scenarioResult = New-MeAndAIScenarioResult -Context $scenarioEvidenceContext
Write-Host 'Canonical helper ownership contracts passed.' -ForegroundColor Green
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
