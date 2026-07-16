Set-StrictMode -Version Latest

$script:MeAndAIAdoptionTargetPaths = @(
    '.gitmodules', '.ai/protocol', 'AGENTS.md',
    '.ai/memory/README.md', '.ai/memory/project.md',
    '.ai/memory/log/README.md', 'docs/ideas/README.md',
    '.github/ISSUE_TEMPLATE/bug.yml',
    '.github/ISSUE_TEMPLATE/epic.yml',
    '.github/ISSUE_TEMPLATE/feature.yml',
    '.github/ISSUE_TEMPLATE/finding.yml',
    '.github/ISSUE_TEMPLATE/subfeature.yml',
    '.github/ISSUE_TEMPLATE/task.yml',
    '.github/PULL_REQUEST_TEMPLATE.md',
    '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
    '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
)
$script:MeAndAIAdoptionProposedPaths = @(
    '.github/workflows/meandai-protocol-update.yml'
) + @($script:MeAndAIAdoptionTargetPaths)
$script:MeAndAIRequiredAdoptionTasks = @(
    'Create or reconcile the repository labels required by the protocol.',
    'Create project-owned feature and decision records for adoption.',
    'Tailor project-local memory without importing protocol-repository facts.',
    'Resolve every collision through semantic review; do not overwrite blindly.',
    'Create and run the project test evidence required by DoR and DoD.',
    'Verify all documentation links and traceability references.',
    'Remove the manifest before marking the pull request ready or merging it.'
)

function Test-MeAndAIExactOrdinalSequence {
    param(
        [AllowEmptyCollection()][object[]]$Actual,
        [AllowEmptyCollection()][object[]]$Expected
    )

    $actualValues = @($Actual | ForEach-Object { [string]$_ })
    $expectedValues = @($Expected | ForEach-Object { [string]$_ })
    if ($actualValues.Count -ne $expectedValues.Count) {
        return $false
    }
    for ($index = 0; $index -lt $actualValues.Count; $index++) {
        if ($actualValues[$index] -cne $expectedValues[$index]) {
            return $false
        }
    }
    return $true
}

function Test-MeAndAIUniqueCanonicalPaths {
    param([AllowEmptyCollection()][object[]]$Paths)

    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($value in @($Paths)) {
        $path = [string]$value
        if ([string]::IsNullOrWhiteSpace($path) -or -not $seen.Add($path)) {
            return $false
        }
    }
    return $true
}

function Get-MeAndAIRequiredAdoptionTasks {
    return @($script:MeAndAIRequiredAdoptionTasks)
}

function Get-MeAndAIAdoptionTargetPaths {
    return @($script:MeAndAIAdoptionTargetPaths)
}

function Get-MeAndAIAdoptionProposedPaths {
    return @($script:MeAndAIAdoptionProposedPaths)
}

function Test-MeAndAIExactAdoptionManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$TargetTag,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [Parameter(Mandatory)][string]$ExpectedState,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ExpectedCollisions
    )

    if ($null -eq $Manifest -or $Manifest -is [array]) {
        return $false
    }
    $manifestProperties = @(
        'schema', 'operation', 'state', 'repository', 'targetTag', 'protocolSha',
        'collisions', 'proposedPaths', 'requiredTasks'
    )
    $actualProperties = @($Manifest.PSObject.Properties | ForEach-Object { $_.Name })
    if ($actualProperties.Count -ne $manifestProperties.Count -or
        @($manifestProperties | Where-Object {
            $actualProperties -cnotcontains $_
        }).Count -ne 0) {
        return $false
    }

    if (($Manifest.schema -isnot [int] -and $Manifest.schema -isnot [long]) -or
        [long]$Manifest.schema -ne 1 -or
        [string]$Manifest.operation -cne 'ai-capabilities-adoption' -or
        [string]$Manifest.state -cne $ExpectedState -or
        -not ([string]$Manifest.repository).Equals(
            $Repository, [StringComparison]::OrdinalIgnoreCase
        ) -or
        [string]$Manifest.targetTag -cne $TargetTag -or
        [string]$Manifest.protocolSha -cne $ProtocolSha) {
        return $false
    }

    if ($Manifest.collisions -isnot [array] -or
        $Manifest.proposedPaths -isnot [array] -or
        $Manifest.requiredTasks -isnot [array] -or
        -not (Test-MeAndAIUniqueCanonicalPaths -Paths @($Manifest.collisions)) -or
        -not (Test-MeAndAIUniqueCanonicalPaths -Paths @($Manifest.proposedPaths)) -or
        -not (Test-MeAndAIExactOrdinalSequence -Actual @($Manifest.collisions) `
            -Expected @($ExpectedCollisions)) -or
        -not (Test-MeAndAIExactOrdinalSequence -Actual @($Manifest.proposedPaths) `
            -Expected $script:MeAndAIAdoptionProposedPaths) -or
        -not (Test-MeAndAIExactOrdinalSequence -Actual @($Manifest.requiredTasks) `
            -Expected $script:MeAndAIRequiredAdoptionTasks)) {
        return $false
    }

    return $true
}

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
        'ManifestExists', 'RemoteBranchExists', 'OpenPullRequestCount',
        'ExistingProposalValid'
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
        $Snapshot.ExistingProposalValid -isnot [bool] -or
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
        if (-not [bool]$Snapshot.ExistingProposalValid) {
            return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
                -ProposalMode 'None' -Collisions @($collisions) `
                -Diagnostics @('The existing adoption proposal failed ownership validation.')
        }
        return New-MeAndAICapabilitiesPlan -State 'PendingAdoption' `
            -ProposalMode 'None' -Collisions @($collisions) `
            -Diagnostics @('A deterministic adoption proposal already exists.')
    }
    if ([bool]$Snapshot.ExistingProposalValid) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @($collisions) `
            -Diagnostics @('Ownership evidence exists without one deterministic proposal.')
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

Export-ModuleMember -Function @(
    'Get-MeAndAIAdoptionProposedPaths',
    'Get-MeAndAIAdoptionTargetPaths',
    'Get-MeAndAIRequiredAdoptionTasks',
    'Resolve-MeAndAICapabilitiesLifecycle',
    'Test-MeAndAIExactAdoptionManifest'
)
