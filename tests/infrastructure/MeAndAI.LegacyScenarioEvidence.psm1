Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'MeAndAI.ScenarioEvidence.psm1')

$roleContractPath = Join-Path (Split-Path -Parent $PSScriptRoot) `
    'test-role-boundaries.psd1'
$roleContract = Import-PowerShellDataFile -LiteralPath $roleContractPath
if ($roleContract -isnot [System.Collections.IDictionary] -or
    -not $roleContract.Contains('SchemaVersion') -or
    [long]$roleContract['SchemaVersion'] -ne 1 -or
    -not $roleContract.Contains('LegacyScenarioEvidenceOwners') -or
    $roleContract['LegacyScenarioEvidenceOwners'] -isnot [Array]) {
    throw 'Legacy scenario evidence owner contract is invalid.'
}

$script:AllowedLegacyOwners =
    [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
foreach ($ownerValue in @($roleContract['LegacyScenarioEvidenceOwners'])) {
    $owner = [string]$ownerValue
    if ([string]::IsNullOrWhiteSpace($owner) -or
        -not $script:AllowedLegacyOwners.Add($owner)) {
        throw "Legacy scenario evidence owner contract contains an invalid or duplicate owner '$owner'."
    }
}
if ($script:AllowedLegacyOwners.Count -eq 0) {
    throw 'Legacy scenario evidence owner contract must not be empty.'
}

$script:LegacyConfirmedScenarioIds =
    [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )

function Confirm-MeAndAILegacyScenarioEvidence {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$TestId)

    if ($TestId -cnotmatch '^TEST-[0-9]{4}$') {
        throw "Invalid legacy scenario evidence identity '$TestId'."
    }
    [void]$script:LegacyConfirmedScenarioIds.Add($TestId)
}

function Get-MeAndAILegacySourceBoundScenarioIds {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$SourcePaths)

    $ids = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($sourcePath in $SourcePaths) {
        $resolvedPath = (Resolve-Path -LiteralPath $sourcePath).Path
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $resolvedPath,
            [ref]$tokens,
            [ref]$errors
        )
        if ($errors.Count -gt 0) {
            throw "Legacy scenario evidence source '$resolvedPath' does not parse: $($errors[0].Message)"
        }

        $assertionNodes = @($ast.FindAll({
            param($node)
            if ($node -is
                [System.Management.Automation.Language.ThrowStatementAst]) {
                return $true
            }
            if ($node -isnot
                [System.Management.Automation.Language.CommandAst]) {
                return $false
            }
            return $node.GetCommandName() -cin @(
                'Add-Failure', 'Assert-Equal'
            )
        }, $true))
        foreach ($node in $assertionNodes) {
            foreach ($match in [regex]::Matches(
                $node.Extent.Text,
                '(?<![A-Za-z0-9-])TEST-[0-9]{4}(?![A-Za-z0-9-])'
            )) {
                [void]$ids.Add([string]$match.Value)
            }
        }
    }
    return @($ids | Sort-Object)
}

function New-MeAndAILegacyScenarioResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Owner,
        [Parameter(Mandatory)][string[]]$SourcePaths,
        [Parameter(Mandatory)][string]$AuthorityPath
    )

    if (-not $script:AllowedLegacyOwners.Contains($Owner)) {
        throw "Legacy scenario evidence is not authorized for '$Owner'."
    }

    $context = New-MeAndAIScenarioEvidenceContext `
        -Owner $Owner -AuthorityPath $AuthorityPath
    $evidenceIds = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($testId in @(Get-MeAndAILegacySourceBoundScenarioIds `
        -SourcePaths $SourcePaths)) {
        [void]$evidenceIds.Add([string]$testId)
    }
    foreach ($testId in $script:LegacyConfirmedScenarioIds) {
        [void]$evidenceIds.Add([string]$testId)
    }

    [string[]]$sortedEvidenceIds = @($evidenceIds)
    [Array]::Sort($sortedEvidenceIds, [StringComparer]::Ordinal)
    foreach ($testId in $sortedEvidenceIds) {
        Confirm-MeAndAIScenarioEvidence -Context $context -TestId $testId
    }
    return New-MeAndAIScenarioResult -Context $context
}

Export-ModuleMember -Function @(
    'Confirm-MeAndAILegacyScenarioEvidence',
    'Get-MeAndAILegacySourceBoundScenarioIds',
    'New-MeAndAILegacyScenarioResult'
)
