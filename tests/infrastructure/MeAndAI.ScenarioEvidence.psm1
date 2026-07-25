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

function Assert-MeAndAICanonicalCaseOwner {
    param([Parameter(Mandatory)][string]$CaseOwner)

    $invalid = [string]::IsNullOrWhiteSpace($CaseOwner) -or
        $CaseOwner.Trim() -cne $CaseOwner -or
        $CaseOwner.Contains('\') -or
        $CaseOwner.StartsWith('/', [StringComparison]::Ordinal) -or
        -not $CaseOwner.EndsWith('.case.ps1', [StringComparison]::Ordinal)
    if (-not $invalid) {
        foreach ($segment in $CaseOwner.Split('/')) {
            if ([string]::IsNullOrWhiteSpace($segment) -or
                $segment -ceq '.' -or $segment -ceq '..') {
                $invalid = $true
                break
            }
        }
    }
    if ($invalid) {
        throw "Case owner '$CaseOwner' must be one canonical repository-relative path ending in '.case.ps1'."
    }
}

function Resolve-MeAndAIScenarioAuthority {
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
    return [pscustomobject]@{
        Ids = $sortedExpectedIds
        IdSet = $expectedIdSet
    }
}

function New-MeAndAIEvidenceContext {
    param(
        [Parameter(Mandatory)][ValidateSet('Scenario', 'Case')][string]$Kind,
        [Parameter(Mandatory)][string]$SuiteOwner,
        [AllowNull()][string]$CaseOwner,
        [Parameter(Mandatory)][object[]]$ExpectedIds
    )

    $expectedIdSet = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($testId in @($ExpectedIds)) {
        if (-not $expectedIdSet.Add([string]$testId)) {
            throw "Evidence context duplicates '$testId'."
        }
    }
    [string[]]$sortedExpectedIds = @($expectedIdSet)
    [Array]::Sort($sortedExpectedIds, [StringComparer]::Ordinal)

    $contextId = [guid]::NewGuid().ToString('N')
    $state = [pscustomobject][ordered]@{
        Kind = $Kind
        Owner = if ($Kind -ceq 'Case') { $CaseOwner } else { $SuiteOwner }
        SuiteOwner = $SuiteOwner
        CaseOwner = $CaseOwner
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

    $authority = Resolve-MeAndAIScenarioAuthority -Owner $Owner `
        -AuthorityPath $AuthorityPath
    return New-MeAndAIEvidenceContext -Kind Scenario -SuiteOwner $Owner `
        -ExpectedIds @($authority.Ids)
}

function New-MeAndAICaseEvidenceContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SuiteOwner,
        [Parameter(Mandatory)][string]$CaseOwner,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$TestIds,
        [Parameter(Mandatory)][string]$AuthorityPath
    )

    Assert-MeAndAICanonicalCaseOwner -CaseOwner $CaseOwner
    $authority = Resolve-MeAndAIScenarioAuthority -Owner $SuiteOwner `
        -AuthorityPath $AuthorityPath
    $caseIds = [System.Collections.Generic.List[string]]::new()
    $caseIdSet = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($rawTestId in @($TestIds)) {
        $testId = [string]$rawTestId
        Assert-MeAndAIScenarioTestId -TestId $testId
        if (-not $caseIdSet.Add($testId)) {
            throw "Case evidence for '$CaseOwner' duplicates '$testId'."
        }
        if (-not $authority.IdSet.Contains($testId)) {
            throw "Case evidence '$testId' is not owned by suite '$SuiteOwner'."
        }
        [void]$caseIds.Add($testId)
    }
    if ($caseIds.Count -eq 0) {
        throw "Case evidence for '$CaseOwner' must declare a non-empty canonical subset."
    }

    return New-MeAndAIEvidenceContext -Kind Case -SuiteOwner $SuiteOwner `
        -CaseOwner $CaseOwner -ExpectedIds $caseIds.ToArray()
}

function Confirm-MeAndAIEvidence {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][ValidateSet('Scenario', 'Case')][string]$Kind,
        [Parameter(Mandatory)][string]$TestId
    )

    $state = Get-MeAndAIScenarioEvidenceContextState -Context $Context
    if ([string]$state.Kind -cne $Kind) {
        throw "$Kind evidence requires a $Kind context."
    }
    if ($state.Finalized) {
        throw "$Kind evidence context for '$($state.Owner)' is already finalized."
    }

    Assert-MeAndAIScenarioTestId -TestId $TestId
    if (-not $state.ExpectedIdSet.Contains($TestId)) {
        if ($Kind -ceq 'Scenario') {
            throw "Runtime scenario evidence '$TestId' is not owned by '$($state.Owner)'."
        }
        throw "Runtime case evidence '$TestId' is not assigned to case '$($state.CaseOwner)' for suite '$($state.SuiteOwner)'."
    }
    if (-not $state.ConfirmedIds.Add($TestId)) {
        throw "Runtime $($Kind.ToLowerInvariant()) evidence '$TestId' was confirmed more than once for '$($state.Owner)'."
    }
}

function Complete-MeAndAIEvidenceContext {
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][ValidateSet('Scenario', 'Case')][string]$Kind
    )

    $state = Get-MeAndAIScenarioEvidenceContextState -Context $Context
    if ([string]$state.Kind -cne $Kind) {
        throw "$Kind evidence requires a $Kind context."
    }
    if ($state.Finalized) {
        throw "$Kind evidence context for '$($state.Owner)' is already finalized."
    }
    $state.Finalized = $true

    $missingIds = @($state.ExpectedIds | Where-Object {
        -not $state.ConfirmedIds.Contains([string]$_)
    })
    if ($missingIds.Count -gt 0) {
        throw "$Kind evidence for '$($state.Owner)' is missing or unexecuted: $($missingIds -join ', ')."
    }

    [string[]]$passedIds = @($state.ConfirmedIds)
    [Array]::Sort($passedIds, [StringComparer]::Ordinal)
    return [pscustomobject]@{
        State = $state
        Passed = $passedIds
    }
}

function Confirm-MeAndAIScenarioEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$TestId
    )

    Confirm-MeAndAIEvidence -Context $Context -Kind Scenario -TestId $TestId
}

function Confirm-MeAndAICaseEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][string]$TestId
    )

    Confirm-MeAndAIEvidence -Context $Context -Kind Case -TestId $TestId
}

function New-MeAndAIScenarioResult {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Context)

    $completion = Complete-MeAndAIEvidenceContext -Context $Context `
        -Kind Scenario
    return [ordered]@{
        schema = 1
        owner = [string]$completion.State.Owner
        passed = [string[]]$completion.Passed
    }
}

function New-MeAndAICaseResult {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Context)

    $completion = Complete-MeAndAIEvidenceContext -Context $Context -Kind Case
    return [ordered]@{
        schema = 1
        suite = [string]$completion.State.SuiteOwner
        case = [string]$completion.State.CaseOwner
        passed = [string[]]$completion.Passed
    }
}

Export-ModuleMember -Function @(
    'New-MeAndAIScenarioEvidenceContext',
    'Confirm-MeAndAIScenarioEvidence',
    'New-MeAndAIScenarioResult',
    'New-MeAndAICaseEvidenceContext',
    'Confirm-MeAndAICaseEvidence',
    'New-MeAndAICaseResult'
)
