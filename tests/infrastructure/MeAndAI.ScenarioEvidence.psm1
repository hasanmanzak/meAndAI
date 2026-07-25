Set-StrictMode -Version Latest

$script:ScenarioEvidenceContextType = 'MeAndAI.ScenarioEvidenceContext'
$script:ScenarioEvidenceContexts =
    [System.Collections.Generic.Dictionary[string, object]]::new(
        [System.StringComparer]::Ordinal
    )

function Assert-MeAndAIScenarioTestId {
    param([Parameter(Mandatory)][string]$TestId)

    if ($TestId -cnotmatch '^TEST-[0-9]{4}$') {
        throw "Invalid scenario evidence identity '$TestId'."
    }
}

function Get-MeAndAIScenarioEvidenceContextState {
    param([Parameter(Mandatory)][object]$Context)

    if ($null -eq $Context -or
        $Context.PSObject.TypeNames -cnotcontains
            $script:ScenarioEvidenceContextType) {
        throw 'The meAndAI scenario evidence context is invalid.'
    }

    $idProperty = $Context.PSObject.Properties['Id']
    if ($null -eq $idProperty -or
        [string]::IsNullOrWhiteSpace([string]$idProperty.Value) -or
        -not $script:ScenarioEvidenceContexts.ContainsKey(
            [string]$idProperty.Value)) {
        throw 'The meAndAI scenario evidence context is unknown.'
    }

    return $script:ScenarioEvidenceContexts[[string]$idProperty.Value]
}

function New-MeAndAIScenarioEvidenceContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Owner,
        [Parameter(Mandatory)][string]$AuthorityPath
    )

    if ([string]::IsNullOrWhiteSpace($Owner)) {
        throw 'Scenario evidence owner must not be empty.'
    }

    $resolvedAuthorityPath = (Resolve-Path -LiteralPath $AuthorityPath `
        -ErrorAction Stop).Path
    if (-not (Test-Path -LiteralPath $resolvedAuthorityPath -PathType Leaf)) {
        throw "Scenario authority '$resolvedAuthorityPath' is not a file."
    }

    $authority = Import-PowerShellDataFile -LiteralPath $resolvedAuthorityPath
    if ($authority -isnot [System.Collections.IDictionary] -or
        -not $authority.Contains('SchemaVersion') -or
        [long]$authority['SchemaVersion'] -ne 1) {
        throw 'Scenario authority schema version must be 1.'
    }
    if (-not $authority.Contains('Authorities')) {
        throw 'Scenario authority must expose one canonical authority array.'
    }

    $ownerAuthorities = [System.Collections.Generic.List[object]]::new()
    foreach ($entry in @($authority['Authorities'])) {
        if ($entry -is [System.Collections.IDictionary] -and
            [string]$entry['Evidence'] -ceq 'ExecutableSuite' -and
            [string]$entry['Owner'] -ceq $Owner) {
            [void]$ownerAuthorities.Add($entry)
        }
    }
    if ($ownerAuthorities.Count -ne 1) {
        throw "Scenario authority for '$Owner' is missing or ambiguous."
    }

    $ownerAuthority = $ownerAuthorities[0]
    if (-not $ownerAuthority.Contains('TestIds')) {
        throw "Scenario authority for '$Owner' has no test IDs."
    }

    $expectedIds = [System.Collections.Generic.List[string]]::new()
    $expectedIdSet = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($rawTestId in @($ownerAuthority['TestIds'])) {
        $testId = [string]$rawTestId
        Assert-MeAndAIScenarioTestId -TestId $testId
        if (-not $expectedIdSet.Add($testId)) {
            throw "Scenario authority for '$Owner' duplicates '$testId'."
        }
        [void]$expectedIds.Add($testId)
    }
    if ($expectedIds.Count -eq 0) {
        throw "Scenario authority for '$Owner' has no test IDs."
    }

    [string[]]$sortedExpectedIds = $expectedIds.ToArray()
    [Array]::Sort($sortedExpectedIds, [StringComparer]::Ordinal)
    $contextId = [guid]::NewGuid().ToString('N')
    $state = [pscustomobject][ordered]@{
        Owner = $Owner
        ExpectedIds = $sortedExpectedIds
        ExpectedIdSet = $expectedIdSet
        ConfirmedIds = [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::Ordinal
        )
        Finalized = $false
    }
    $script:ScenarioEvidenceContexts.Add($contextId, $state)

    $context = [pscustomobject][ordered]@{ Id = $contextId }
    $context.PSObject.TypeNames.Insert(
        0, $script:ScenarioEvidenceContextType)
    return $context
}

function Confirm-MeAndAIScenarioEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$TestId
    )

    $state = Get-MeAndAIScenarioEvidenceContextState -Context $Context
    if ($state.Finalized) {
        throw "Scenario evidence context for '$($state.Owner)' is already finalized."
    }

    Assert-MeAndAIScenarioTestId -TestId $TestId
    if (-not $state.ExpectedIdSet.Contains($TestId)) {
        throw "Runtime scenario evidence '$TestId' is not owned by '$($state.Owner)'."
    }
    if (-not $state.ConfirmedIds.Add($TestId)) {
        throw "Runtime scenario evidence '$TestId' was confirmed more than once for '$($state.Owner)'."
    }
}

function New-MeAndAIScenarioResult {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Context)

    $state = Get-MeAndAIScenarioEvidenceContextState -Context $Context
    if ($state.Finalized) {
        throw "Scenario evidence context for '$($state.Owner)' is already finalized."
    }
    $state.Finalized = $true

    $missingIds = @($state.ExpectedIds | Where-Object {
        -not $state.ConfirmedIds.Contains([string]$_)
    })
    if ($missingIds.Count -gt 0) {
        throw "Scenario evidence for '$($state.Owner)' is missing or unexecuted: $($missingIds -join ', ')."
    }

    [string[]]$passedIds = @($state.ConfirmedIds)
    [Array]::Sort($passedIds, [StringComparer]::Ordinal)
    return [ordered]@{
        schema = 1
        owner = [string]$state.Owner
        passed = $passedIds
    }
}

Export-ModuleMember -Function @(
    'New-MeAndAIScenarioEvidenceContext',
    'Confirm-MeAndAIScenarioEvidence',
    'New-MeAndAIScenarioResult'
)
