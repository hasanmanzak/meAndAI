Set-StrictMode -Version Latest

$script:ConfirmedScenarioIds = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::Ordinal
)

function Confirm-MeAndAIScenarioEvidence {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$TestId)

    if ($TestId -cnotmatch '^TEST-[0-9]{4}$') {
        throw "Invalid scenario evidence identity '$TestId'."
    }
    [void]$script:ConfirmedScenarioIds.Add($TestId)
}

function Get-MeAndAISourceBoundScenarioIds {
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
            throw "Scenario evidence source '$resolvedPath' does not parse: $($errors[0].Message)"
        }

        $assertionNodes = @($ast.FindAll({
            param($node)
            if ($node -is [System.Management.Automation.Language.ThrowStatementAst]) {
                return $true
            }
            if ($node -isnot [System.Management.Automation.Language.CommandAst]) {
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

function New-MeAndAIScenarioResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Owner,
        [Parameter(Mandatory)][string[]]$SourcePaths,
        [Parameter(Mandatory)][string]$AuthorityPath
    )

    $authority = Import-PowerShellDataFile -LiteralPath $AuthorityPath
    if ([long]$authority.SchemaVersion -ne 1) {
        throw 'Scenario authority schema version must be 1.'
    }
    $ownerAuthorities = @($authority.Authorities | Where-Object {
        [string]$_.Evidence -ceq 'ExecutableSuite' -and
        [string]$_.Owner -ceq $Owner
    })
    if ($ownerAuthorities.Count -ne 1) {
        throw "Scenario authority for '$Owner' is missing or ambiguous."
    }

    $expectedIds = @($ownerAuthorities[0].TestIds | ForEach-Object {
        [string]$_
    } | Sort-Object)
    $sourceIds = @(Get-MeAndAISourceBoundScenarioIds -SourcePaths $SourcePaths)
    $evidenceIds = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($testId in $sourceIds) {
        [void]$evidenceIds.Add($testId)
    }
    foreach ($testId in $script:ConfirmedScenarioIds) {
        if ($expectedIds -cnotcontains $testId) {
            throw "Runtime scenario evidence '$testId' is not owned by '$Owner'."
        }
        [void]$evidenceIds.Add($testId)
    }

    $missingIds = @($expectedIds | Where-Object {
        -not $evidenceIds.Contains($_)
    })
    if ($missingIds.Count -gt 0) {
        throw "Scenario evidence for '$Owner' is not source-bound: $($missingIds -join ', ')."
    }

    return [ordered]@{
        schema = 1
        owner = $Owner
        passed = $expectedIds
    }
}

Export-ModuleMember -Function @(
    'Confirm-MeAndAIScenarioEvidence',
    'Get-MeAndAISourceBoundScenarioIds',
    'New-MeAndAIScenarioResult'
)
