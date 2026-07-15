Set-StrictMode -Version Latest

function New-MeAndAICapabilitiesPlan {
    param(
        [string]$State,
        [string]$ProposalMode,
        [object[]]$Collisions,
        [object[]]$Diagnostics
    )

    return [pscustomobject]@{
        SchemaVersion = 1
        State = $State
        ProposalMode = $ProposalMode
        Collisions = @($Collisions | ForEach-Object { [string]$_ })
        Diagnostics = @($Diagnostics | ForEach-Object { [string]$_ })
    }
}

function Resolve-MeAndAICapabilitiesLifecycle {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Snapshot)

    $required = @(
        'SchemaVersion', 'LocalUpdaterState', 'SeedWorkflowState', 'Collisions',
        'ManifestExists', 'RemoteBranchExists', 'OpenPullRequestCount'
    )
    $missing = @($required | Where-Object {
        $_ -notin $Snapshot.PSObject.Properties.Name
    })
    if ($missing.Count -gt 0) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @() `
            -Diagnostics @("Lifecycle snapshot is missing: $($missing -join ', ').")
    }

    if ($Snapshot.SchemaVersion -isnot [int] -and
        $Snapshot.SchemaVersion -isnot [long]) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @() `
            -Diagnostics @('Lifecycle schema version must be an integer.')
    }
    if ([long]$Snapshot.SchemaVersion -ne 1) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @() `
            -Diagnostics @("Unsupported lifecycle schema '$($Snapshot.SchemaVersion)'.")
    }

    $localUpdaterState = [string]$Snapshot.LocalUpdaterState
    $seedWorkflowState = [string]$Snapshot.SeedWorkflowState
    $allowedUpdaterStates = @('Absent', 'Partial', 'Complete')
    $allowedSeedStates = @('Exact', 'Missing', 'Drifted')
    if ($localUpdaterState -cnotin $allowedUpdaterStates -or
        $seedWorkflowState -cnotin $allowedSeedStates) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @() `
            -Diagnostics @('Lifecycle snapshot contains an unknown state.')
    }

    if ($Snapshot.ManifestExists -isnot [bool] -or
        $Snapshot.RemoteBranchExists -isnot [bool] -or
        ($Snapshot.OpenPullRequestCount -isnot [int] -and
         $Snapshot.OpenPullRequestCount -isnot [long]) -or
        [long]$Snapshot.OpenPullRequestCount -lt 0) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @() `
            -Diagnostics @('Lifecycle snapshot contains invalid ownership values.')
    }

    $collisions = [System.Collections.Generic.List[string]]::new()
    $seenCollisions = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($value in @($Snapshot.Collisions)) {
        $path = [string]$value
        if ([string]::IsNullOrWhiteSpace($path) -or
            -not $seenCollisions.Add($path)) {
            return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
                -ProposalMode 'None' -Collisions @($collisions) `
                -Diagnostics @('Lifecycle collision paths are empty or ambiguous.')
        }
        $collisions.Add($path)
    }

    if ($seedWorkflowState -cne 'Exact') {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @($collisions) `
            -Diagnostics @('The committed seed workflow does not match the pinned release.')
    }
    if ([bool]$Snapshot.ManifestExists) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @($collisions) `
            -Diagnostics @('The transient adoption manifest already exists.')
    }

    $branchExists = [bool]$Snapshot.RemoteBranchExists
    $pullRequestCount = [long]$Snapshot.OpenPullRequestCount
    if ($branchExists -and $pullRequestCount -eq 1) {
        return New-MeAndAICapabilitiesPlan -State 'PendingAdoption' `
            -ProposalMode 'None' -Collisions @($collisions) `
            -Diagnostics @('A deterministic adoption proposal already exists.')
    }
    if ($branchExists -or $pullRequestCount -ne 0) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @($collisions) `
            -Diagnostics @('Adoption branch and pull-request ownership are inconsistent.')
    }

    if ($localUpdaterState -ceq 'Complete') {
        if ($collisions.Count -ne 0) {
            return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
                -ProposalMode 'None' -Collisions @($collisions) `
                -Diagnostics @('A complete updater snapshot cannot contain adoption collisions.')
        }
        return New-MeAndAICapabilitiesPlan -State 'Update' `
            -ProposalMode 'None' -Collisions @() -Diagnostics @()
    }

    if ($localUpdaterState -ceq 'Partial' -and $collisions.Count -eq 0) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @() `
            -Diagnostics @('A partial updater snapshot must identify its colliding paths.')
    }
    if ($collisions.Count -gt 0) {
        return New-MeAndAICapabilitiesPlan -State 'AdoptionReviewRequired' `
            -ProposalMode 'ManifestOnly' -Collisions @($collisions) -Diagnostics @()
    }

    return New-MeAndAICapabilitiesPlan -State 'BootstrapReady' `
        -ProposalMode 'Full' -Collisions @() -Diagnostics @()
}

Export-ModuleMember -Function 'Resolve-MeAndAICapabilitiesLifecycle'
