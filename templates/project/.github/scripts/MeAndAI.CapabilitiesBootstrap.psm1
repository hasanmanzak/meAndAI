Set-StrictMode -Version Latest

$script:MeAndAIAdoptionManifestPath = '.ai/adoption/meandai-capabilities.json'
$script:MeAndAISeedWorkflowPath = '.github/workflows/meandai-protocol-update.yml'
$script:MeAndAIAdoptionTargetPaths = @(
    '.gitmodules', '.ai/protocol', '.ai/meandai-update-state.json', 'AGENTS.md',
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
    $script:MeAndAISeedWorkflowPath
) + @($script:MeAndAIAdoptionTargetPaths)
$script:MeAndAIRequiredAdoptionTasks = @(
    'Create or reconcile the repository labels required by the protocol.',
    'Create project-owned feature and decision records for adoption.',
    'Apply the manifest-selected adoption strategy; do not infer or change it.',
    'Tailor project-local memory without importing protocol-repository facts.',
    'Resolve every collision through semantic review; do not overwrite blindly.',
    'Create and run the project test evidence required by DoR and DoD.',
    'Verify all documentation links and traceability references.',
    'Remove the manifest before marking the pull request ready or merging it.'
)
$script:MeAndAIProtocolSurfaceFiles = @(
    'AGENTS.md', 'CLAUDE.md', 'GEMINI.md', 'PROTOCOL.md', 'CONTRIBUTING.md',
    '.cursorrules', '.windsurfrules', '.github/copilot-instructions.md',
    '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
    '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1',
    '.ai/protocol', '.ai/meandai-update-state.json',
    'FEATURE_BACKLOG.md', 'ACTIVE_FINDINGS.md', 'DECISIONS.md',
    'WORK_INDEX.md', 'SESSION_HANDOFF.md', 'PROJECT_STATE.md',
    'PROJECT_METRICS.md', 'RELEASES.md',
    'ai/FEATURE_BACKLOG.md', 'ai/ACTIVE_FINDINGS.md', 'ai/DECISIONS.md',
    'ai/WORK_INDEX.md', 'ai/SESSION_HANDOFF.md', 'ai/PROJECT_STATE.md',
    'ai/PROJECT_METRICS.md', 'ai/RELEASES.md'
)
$script:MeAndAIProtocolSurfaceRoots = @(
    '.ai/protocol/', '.ai/memory/', '.cursor/rules/', '.windsurf/rules/',
    '.github/instructions/',
    'docs/features/', 'docs/decisions/', 'docs/findings/',
    'docs/governance/', 'docs/ideas/', 'docs/agent-prompts/'
)
$script:MeAndAILegacyCommonAuthorityFiles = @(
    'AGENTS.md', 'CLAUDE.md', 'GEMINI.md', 'PROTOCOL.md',
    '.cursorrules', '.windsurfrules', '.github/copilot-instructions.md'
)
$script:MeAndAILegacyAiGovernanceFiles = @(
    'ai/FEATURE_BACKLOG.md', 'ai/ACTIVE_FINDINGS.md', 'ai/DECISIONS.md',
    'ai/WORK_INDEX.md', 'ai/SESSION_HANDOFF.md', 'ai/PROJECT_STATE.md',
    'ai/PROJECT_METRICS.md', 'ai/RELEASES.md'
)
$script:MeAndAILegacyCommonAuthorityRoots = @(
    '.cursor/rules/', '.windsurf/rules/', '.github/instructions/'
)
$script:MeAndAILegacyGovernanceRoots = @(
    '.ai/protocol/', '.ai/memory/', '.cursor/rules/', '.windsurf/rules/',
    '.github/instructions/',
    'docs/governance/', 'docs/agent-prompts/'
)
$script:MeAndAIResolvedAdoptionStrategies = @(
    'FreshAdoption', 'FullMigration', 'HybridReconciliation', 'CleanStart'
)
$script:MeAndAIProtocolSurfaceMaximumCount = 256
$script:MeAndAIProtocolSurfaceMaximumUtf8Bytes = 16384
$script:MeAndAISourceEnforcedRequiredPaths = @(
    '.ai/meandai-update-state.json',
    '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
    '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
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
        if (-not (Test-MeAndAICanonicalRepositoryPath -Path $path) -or
            -not $seen.Add($path)) {
            return $false
        }
    }
    return $true
}

function Test-MeAndAIExactCanonicalSurfaceSequence {
    param(
        [AllowEmptyCollection()][object[]]$Actual,
        [AllowEmptyCollection()][object[]]$Expected
    )

    $actualValues = @($Actual)
    $expectedValues = @($Expected | ForEach-Object { [string]$_ })
    if ($actualValues.Count -ne $expectedValues.Count) {
        return $false
    }
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    for ($index = 0; $index -lt $actualValues.Count; $index++) {
        $value = $actualValues[$index]
        if ($value -isnot [string] -or
            -not (Test-MeAndAICanonicalRepositoryPath -Path $value) -or
            -not $seen.Add($value) -or
            $value -cne $expectedValues[$index]) {
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

function Get-MeAndAIProtocolAssessmentLimits {
    return [pscustomobject]@{
        MaximumSurfaceCount = [int]$script:MeAndAIProtocolSurfaceMaximumCount
        MaximumSurfaceUtf8Bytes =
            [int]$script:MeAndAIProtocolSurfaceMaximumUtf8Bytes
    }
}

function Test-MeAndAICanonicalRepositoryPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or
        [IO.Path]::IsPathRooted($Path) -or
        $Path.Contains('\') -or
        $Path -match '[\x00-\x1f]') {
        return $false
    }
    $segments = @($Path.Split('/'))
    return $segments.Count -gt 0 -and
        @($segments | Where-Object {
            $_ -ceq '' -or $_ -ceq '.' -or $_ -ceq '..'
        }).Count -eq 0
}

function Assert-MeAndAIProtocolAssessmentPathCasing {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $actualSegments = @($Path.Split('/'))
    $canonicalPaths = @(
        $script:MeAndAIAdoptionManifestPath
    ) + @($script:MeAndAIAdoptionProposedPaths)
    foreach ($canonicalPath in $canonicalPaths) {
        $canonicalSegments = @(([string]$canonicalPath).Split('/'))
        $sharedLength = [Math]::Min(
            $actualSegments.Count,
            $canonicalSegments.Count
        )
        for ($index = 0; $index -lt $sharedLength; $index++) {
            if (-not $actualSegments[$index].Equals(
                    $canonicalSegments[$index],
                    [StringComparison]::OrdinalIgnoreCase)) {
                break
            }
            if ($actualSegments[$index] -cne $canonicalSegments[$index]) {
                throw "Repository path '$Path' uses noncanonical casing for adoption path '$canonicalPath'."
            }
        }
    }
}

function Test-MeAndAIProtocolSurfacePath {
    param([Parameter(Mandatory)][string]$Path)

    if ($Path.Equals('AGENTS.md', [StringComparison]::OrdinalIgnoreCase) -or
        $Path.EndsWith('/AGENTS.md', [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    foreach ($candidate in $script:MeAndAIProtocolSurfaceFiles) {
        if ($Path.Equals($candidate, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    foreach ($root in $script:MeAndAIProtocolSurfaceRoots) {
        if ($Path.Equals($root.TrimEnd('/'), [StringComparison]::OrdinalIgnoreCase) -or
            $Path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Test-MeAndAIProtocolAssessmentRelevantPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$TargetPaths
    )

    if ($Path.Equals(
            $script:MeAndAIAdoptionManifestPath,
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        $Path.Equals(
            $script:MeAndAISeedWorkflowPath,
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        (Test-MeAndAIProtocolSurfacePath -Path $Path)) {
        return $true
    }
    foreach ($value in @($TargetPaths)) {
        $target = [string]$value
        if ($Path.Equals($target, [StringComparison]::OrdinalIgnoreCase) -or
            $Path.StartsWith("$target/", [StringComparison]::OrdinalIgnoreCase) -or
            $target.StartsWith("$Path/", [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Get-MeAndAIProtocolSurfaceInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$Paths = @()
    )

    $seenPaths = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $surfaces = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    [object[]]$pathValues = @()
    if ($null -ne $Paths) {
        $pathValues = [object[]]@($Paths)
    }
    if ($pathValues.Count -eq 1 -and $null -eq $pathValues[0]) {
        $pathValues = [object[]]@()
    }
    foreach ($value in $pathValues) {
        $path = [string]$value
        if (-not (Test-MeAndAICanonicalRepositoryPath -Path $path) -or
            -not $seenPaths.Add($path)) {
            throw "Protocol inventory path '$path' is invalid or case-ambiguous."
        }
        if ((Test-MeAndAIProtocolSurfacePath -Path $path) -and
            $surfaces.Add($path) -and
            ($surfaces.Count -gt $script:MeAndAIProtocolSurfaceMaximumCount -or
             [Text.Encoding]::UTF8.GetByteCount((@($surfaces) -join "`n")) -gt
                $script:MeAndAIProtocolSurfaceMaximumUtf8Bytes)) {
            throw 'Protocol inventory exceeds the bounded assessment budget; maintainer review is required.'
        }
    }
    $result = @($surfaces)
    [Array]::Sort($result, [StringComparer]::Ordinal)
    if ($result.Count -gt $script:MeAndAIProtocolSurfaceMaximumCount -or
        [Text.Encoding]::UTF8.GetByteCount(($result -join "`n")) -gt
            $script:MeAndAIProtocolSurfaceMaximumUtf8Bytes) {
        throw 'Protocol inventory exceeds the bounded assessment budget; maintainer review is required.'
    }
    return @($result)
}

function Test-MeAndAILegacyCommonAuthorityPath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    foreach ($candidate in $script:MeAndAILegacyCommonAuthorityFiles) {
        if ($Path.Equals($candidate, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    foreach ($root in $script:MeAndAILegacyCommonAuthorityRoots) {
        if ($Path.Equals($root.TrimEnd('/'), [StringComparison]::OrdinalIgnoreCase) -or
            $Path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Test-MeAndAIConsumerGovernancePath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if ($Path -ceq 'AGENTS.md' -or
        $Path.EndsWith('/AGENTS.md', [StringComparison]::Ordinal)) {
        return $true
    }
    foreach ($root in @(
        '.ai/memory/',
        'docs/features/', 'docs/decisions/', 'docs/findings/',
        'docs/governance/', 'docs/ideas/', 'docs/agent-prompts/'
    )) {
        if ($Path.StartsWith($root, [StringComparison]::Ordinal) -and
            $Path.EndsWith('.md', [StringComparison]::Ordinal)) {
            return $true
        }
    }
    return $Path.StartsWith(
        'tests/meandai-adoption/',
        [StringComparison]::Ordinal
    )
}

function Test-MeAndAILegacyGovernancePath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if ($Path.Equals('AGENTS.md', [StringComparison]::OrdinalIgnoreCase) -or
        $Path.EndsWith('/AGENTS.md', [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    foreach ($candidate in @(
        $script:MeAndAILegacyCommonAuthorityFiles +
        $script:MeAndAILegacyAiGovernanceFiles
    )) {
        if ($Path.Equals($candidate, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    foreach ($root in $script:MeAndAILegacyGovernanceRoots) {
        if ($Path.Equals($root.TrimEnd('/'), [StringComparison]::OrdinalIgnoreCase) -or
            $Path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Test-MeAndAICleanStartSurfaceSupported {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (Test-MeAndAILegacyGovernancePath -Path $Path) { return $true }
    foreach ($targetPath in $script:MeAndAIAdoptionTargetPaths) {
        if ($Path -ceq [string]$targetPath) {
            return $true
        }
    }
    return $false
}

function Resolve-MeAndAIAdoptionStrategy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RequestedStrategy,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ProtocolSurfaces,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Collisions,
        [Parameter(Mandatory)][bool]$AcknowledgeProtocolRecordLoss
    )

    $allowed = @('Auto', 'FreshAdoption', 'FullMigration',
        'HybridReconciliation', 'CleanStart', 'Abort')
    $diagnostics = [System.Collections.Generic.List[string]]::new()
    if ($RequestedStrategy -cnotin $allowed) {
        $diagnostics.Add("Unsupported adoption strategy '$RequestedStrategy'.")
    }
    if (-not (Test-MeAndAIUniqueCanonicalPaths -Paths $ProtocolSurfaces) -or
        -not (Test-MeAndAIUniqueCanonicalPaths -Paths $Collisions)) {
        $diagnostics.Add('Protocol surfaces or collision paths are empty or ambiguous.')
    }
    $surfaceValues = @($ProtocolSurfaces | ForEach-Object { [string]$_ })
    $sortedSurfaces = @($surfaceValues)
    [Array]::Sort($sortedSurfaces, [StringComparer]::Ordinal)
    if (-not (Test-MeAndAIExactOrdinalSequence -Actual $surfaceValues `
        -Expected $sortedSurfaces)) {
        $diagnostics.Add('Protocol surfaces are not in canonical ordinal order.')
    }
    if ($diagnostics.Count -gt 0) {
        return [pscustomobject]@{
            State = 'BlockedManualReview'
            AdoptionStrategy = ''
            ProtocolSurfaces = @($surfaceValues)
            ProtocolRecordLossAcknowledged = $false
            Diagnostics = @($diagnostics)
        }
    }

    if ($RequestedStrategy -ceq 'Abort') {
        return [pscustomobject]@{
            State = 'Aborted'
            AdoptionStrategy = 'Abort'
            ProtocolSurfaces = @($surfaceValues)
            ProtocolRecordLossAcknowledged = $false
            Diagnostics = @('Initial adoption was aborted by the maintainer.')
        }
    }

    $hasEvidence = $surfaceValues.Count -gt 0
    if ($RequestedStrategy -ceq 'Auto' -and $hasEvidence) {
        return [pscustomobject]@{
            State = 'ProtocolMigrationReviewRequired'
            AdoptionStrategy = ''
            ProtocolSurfaces = @($surfaceValues)
            ProtocolRecordLossAcknowledged = $false
            Diagnostics = @('Existing protocol or governance evidence requires an explicit adoption strategy.')
        }
    }
    $resolved = if ($RequestedStrategy -ceq 'Auto') {
        'FreshAdoption'
    }
    else { $RequestedStrategy }

    if (-not $hasEvidence -and $resolved -cin @(
        'FullMigration', 'HybridReconciliation', 'CleanStart'
    )) {
        return [pscustomobject]@{
            State = 'BlockedManualReview'
            AdoptionStrategy = $resolved
            ProtocolSurfaces = @($surfaceValues)
            ProtocolRecordLossAcknowledged = $false
            Diagnostics = @("$resolved requires detected protocol or governance evidence; use FreshAdoption for an evidence-free repository.")
        }
    }
    if ($resolved -ceq 'FreshAdoption' -and $hasEvidence) {
        return [pscustomobject]@{
            State = 'BlockedManualReview'
            AdoptionStrategy = $resolved
            ProtocolSurfaces = @($surfaceValues)
            ProtocolRecordLossAcknowledged = $false
            Diagnostics = @('FreshAdoption contradicts detected protocol or governance evidence.')
        }
    }
    if ($resolved -ceq 'CleanStart') {
        $unsupportedCleanStartSurfaces = @($surfaceValues | Where-Object {
            -not (Test-MeAndAICleanStartSurfaceSupported -Path ([string]$_))
        })
        if ($unsupportedCleanStartSurfaces.Count -gt 0) {
            return [pscustomobject]@{
                State = 'BlockedManualReview'
                AdoptionStrategy = $resolved
                ProtocolSurfaces = @($surfaceValues)
                ProtocolRecordLossAcknowledged = $false
                Diagnostics = @("CleanStart cannot safely classify detected paths as discardable governance records: $($unsupportedCleanStartSurfaces -join ', ').")
            }
        }
    }
    if ($resolved -ceq 'CleanStart' -and -not $AcknowledgeProtocolRecordLoss) {
        return [pscustomobject]@{
            State = 'BlockedManualReview'
            AdoptionStrategy = $resolved
            ProtocolSurfaces = @($surfaceValues)
            ProtocolRecordLossAcknowledged = $false
            Diagnostics = @('CleanStart requires explicit acknowledgement of protocol record loss.')
        }
    }
    if ($resolved -cne 'CleanStart' -and $AcknowledgeProtocolRecordLoss) {
        return [pscustomobject]@{
            State = 'BlockedManualReview'
            AdoptionStrategy = $resolved
            ProtocolSurfaces = @($surfaceValues)
            ProtocolRecordLossAcknowledged = $false
            Diagnostics = @('Protocol record loss acknowledgement is valid only with CleanStart.')
        }
    }

    return [pscustomobject]@{
        State = 'Resolved'
        AdoptionStrategy = $resolved
        ProtocolSurfaces = @($surfaceValues)
        ProtocolRecordLossAcknowledged = ($resolved -ceq 'CleanStart')
        Diagnostics = @()
    }
}

function Test-MeAndAIExactAdoptionManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$TargetTag,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [Parameter(Mandatory)][string]$ExpectedState,
        [Parameter(Mandatory)][string]$ExpectedAdoptionStrategy,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ExpectedProtocolSurfaces,
        [Parameter(Mandatory)][bool]$ExpectedProtocolRecordLossAcknowledgement,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ExpectedCollisions
    )

    if ($null -eq $Manifest -or $Manifest -is [array]) {
        return $false
    }
    $manifestProperties = @(
        'schema', 'operation', 'state', 'repository', 'targetTag', 'protocolSha',
        'adoptionStrategy', 'protocolSurfaces',
        'protocolRecordLossAcknowledged', 'collisions', 'proposedPaths',
        'requiredTasks'
    )
    $actualProperties = @($Manifest.PSObject.Properties | ForEach-Object { $_.Name })
    if ($actualProperties.Count -ne $manifestProperties.Count -or
        @($manifestProperties | Where-Object {
            $actualProperties -cnotcontains $_
        }).Count -ne 0) {
        return $false
    }

    if (($Manifest.schema -isnot [int] -and $Manifest.schema -isnot [long]) -or
        [long]$Manifest.schema -ne 2 -or
        [string]$Manifest.operation -cne 'ai-capabilities-adoption' -or
        [string]$Manifest.state -cne $ExpectedState -or
        -not ([string]$Manifest.repository).Equals(
            $Repository, [StringComparison]::OrdinalIgnoreCase
        ) -or
        [string]$Manifest.targetTag -cne $TargetTag -or
        [string]$Manifest.protocolSha -cne $ProtocolSha -or
        [string]$Manifest.adoptionStrategy -cne $ExpectedAdoptionStrategy -or
        [string]$Manifest.adoptionStrategy -cnotin $script:MeAndAIResolvedAdoptionStrategies -or
        $Manifest.protocolRecordLossAcknowledged -isnot [bool] -or
        [bool]$Manifest.protocolRecordLossAcknowledged -ne
            $ExpectedProtocolRecordLossAcknowledgement) {
        return $false
    }

    if ($Manifest.protocolSurfaces -isnot [array] -or
        $Manifest.collisions -isnot [array] -or
        $Manifest.proposedPaths -isnot [array] -or
        $Manifest.requiredTasks -isnot [array] -or
        -not (Test-MeAndAIUniqueCanonicalPaths -Paths @($Manifest.protocolSurfaces)) -or
        -not (Test-MeAndAIUniqueCanonicalPaths -Paths @($Manifest.collisions)) -or
        -not (Test-MeAndAIUniqueCanonicalPaths -Paths @($Manifest.proposedPaths)) -or
        -not (Test-MeAndAIExactOrdinalSequence `
            -Actual @($Manifest.protocolSurfaces) `
            -Expected @($ExpectedProtocolSurfaces)) -or
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

function Test-MeAndAIExactAdoptionPullRequestMarker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$RemoteHead,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][string]$BaseBranch,
        [Parameter(Mandatory)][string]$TargetTag,
        [Parameter(Mandatory)][string]$TargetSha,
        [Parameter(Mandatory)][string]$ExpectedActor,
        [Parameter(Mandatory)][string]$ExpectedState,
        [Parameter(Mandatory)][string]$ExpectedAdoptionStrategy,
        [Parameter(Mandatory)][AllowEmptyCollection()]
        [object[]]$ExpectedProtocolSurfaces,
        [Parameter(Mandatory)][bool]$ExpectedProtocolRecordLossAcknowledgement,
        [ValidateSet('Proposed', 'Completed')]
        [string]$ExpectedPhase = 'Proposed'
    )

    foreach ($property in @(
        'number', 'url', 'headRefName', 'headRefOid', 'baseRefName',
        'headRepository', 'author', 'body', 'isDraft', 'state'
    )) {
        if ($null -eq $PullRequest.PSObject.Properties[$property]) {
            return $false
        }
    }
    $expectedDraft = $ExpectedPhase -ceq 'Proposed'
    if ([string]$PullRequest.state -cne 'OPEN' -or
        [string]$PullRequest.headRefName -cne $Branch -or
        [string]$PullRequest.headRefOid -cne $RemoteHead -or
        [string]$PullRequest.baseRefName -cne $BaseBranch -or
        $PullRequest.isDraft -isnot [bool] -or
        [bool]$PullRequest.isDraft -ne $expectedDraft -or
        [string]$PullRequest.number -cnotmatch '^[1-9][0-9]*$' -or
        [string]$PullRequest.url -cnotmatch
            "/pull/$([regex]::Escape([string]$PullRequest.number))/?$") {
        return $false
    }
    if ($null -eq $PullRequest.headRepository -or
        $null -eq $PullRequest.headRepository.PSObject.Properties['nameWithOwner'] -or
        -not ([string]$PullRequest.headRepository.nameWithOwner).Equals(
            $Repository, [StringComparison]::OrdinalIgnoreCase
        ) -or
        $null -eq $PullRequest.author -or
        $null -eq $PullRequest.author.PSObject.Properties['login'] -or
        -not ([string]$PullRequest.author.login).Equals(
            $ExpectedActor, [StringComparison]::OrdinalIgnoreCase
        )) {
        return $false
    }

    $body = [string]$PullRequest.body
    $markerStarts = [regex]::Matches(
        $body, '<!--\s*meandai-capabilities-adoption:',
        [Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
    $markerMatches = [regex]::Matches(
        $body, '<!-- meandai-capabilities-adoption:(?<json>\{[^\r\n]*\}) -->',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if ($markerStarts.Count -ne 1 -or $markerMatches.Count -ne 1) {
        return $false
    }
    try {
        $marker = $markerMatches[0].Groups['json'].Value | ConvertFrom-Json
    }
    catch {
        return $false
    }
    $schemaProperty = $marker.PSObject.Properties['schema']
    if ($null -eq $schemaProperty -or
        ($schemaProperty.Value -isnot [int] -and
         $schemaProperty.Value -isnot [long])) {
        return $false
    }
    $schema = [long]$schemaProperty.Value
    $expectedProperties = if ($schema -eq 2) {
        @('schema', 'state', 'target', 'protocolSha', 'head', 'repository', 'actor')
    }
    elseif ($schema -eq 3) {
        @('schema', 'phase', 'state', 'target', 'protocolSha', 'head',
            'repository', 'actor')
    }
    elseif ($schema -eq 5) {
        @(
            'schema', 'phase', 'state', 'target', 'protocolSha', 'head',
            'adoptionStrategy', 'protocolSurfaces',
            'protocolRecordLossAcknowledged', 'repository', 'actor'
        )
    }
    else {
        return $false
    }
    $actualProperties = @($marker.PSObject.Properties | ForEach-Object {
        $_.Name
    })
    if ($actualProperties.Count -ne $expectedProperties.Count -or
        @($expectedProperties | Where-Object {
            $actualProperties -cnotcontains $_
        }).Count -ne 0) {
        return $false
    }
    $phase = if ($schema -eq 2) { 'Proposed' } else { [string]$marker.phase }
    if (-not (
        $phase -ceq $ExpectedPhase -and
        ($ExpectedPhase -ceq 'Proposed' -or $schema -in @(3, 5)) -and
        [string]$marker.state -ceq $ExpectedState -and
        [string]$marker.target -ceq $TargetTag -and
        [string]$marker.protocolSha -ceq $TargetSha -and
        [string]$marker.head -ceq $RemoteHead -and
        ([string]$marker.repository).Equals(
            $Repository, [StringComparison]::OrdinalIgnoreCase
        ) -and
        ([string]$marker.actor).Equals(
            $ExpectedActor, [StringComparison]::OrdinalIgnoreCase
        ) -and
        (($schema -in @(2, 3) -and
          $ExpectedAdoptionStrategy -cin @('LegacyUnspecified', 'FreshAdoption') -and
          @($ExpectedProtocolSurfaces).Count -eq 0 -and
          -not $ExpectedProtocolRecordLossAcknowledgement) -or
         ($schema -eq 5 -and
          [string]$marker.adoptionStrategy -ceq $ExpectedAdoptionStrategy -and
          $marker.protocolSurfaces -is [array] -and
          (Test-MeAndAIExactCanonicalSurfaceSequence `
              -Actual @($marker.protocolSurfaces) `
              -Expected @($ExpectedProtocolSurfaces)) -and
          $marker.protocolRecordLossAcknowledged -is [bool] -and
          [bool]$marker.protocolRecordLossAcknowledged -eq
              $ExpectedProtocolRecordLossAcknowledgement))
    )) {
        return $false
    }
    return $true
}

function Test-MeAndAIReservedProtocolSubmoduleContract {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Rows,
        [Parameter(Mandatory)]$ProtocolEntry,
        [Parameter(Mandatory)][string]$ProtocolRepository
    )

    $normalizedRows = [System.Collections.Generic.List[string]]::new()
    foreach ($value in @($Rows)) {
        if ($value -isnot [string]) { return $false }
        $row = [string]$value
        $separator = $row.IndexOf("`n", [StringComparison]::Ordinal)
        if ($separator -le 0) {
            return $false
        }
        $normalizedRows.Add($row)
    }
    $sortedRows = [string[]]@($normalizedRows)
    [Array]::Sort($sortedRows, [StringComparer]::Ordinal)
    $protocolPrefix = 'submodule..ai/protocol.'
    $reservedRows = @($sortedRows | Where-Object {
        $row = [string]$_
        $separator = $row.IndexOf("`n", [StringComparison]::Ordinal)
        $key = $row.Substring(0, $separator)
        $value = $row.Substring($separator + 1)
        if ($key.StartsWith(
            $protocolPrefix, [StringComparison]::OrdinalIgnoreCase
        )) {
            return $true
        }
        if (-not [regex]::IsMatch(
            $key, '^submodule\..+\.path$',
            [Text.RegularExpressions.RegexOptions]::IgnoreCase
        )) {
            return $false
        }
        $candidate = $value.Replace('\', '/').Trim('/')
        while ($candidate.StartsWith('./', [StringComparison]::Ordinal)) {
            $candidate = $candidate.Substring(2).TrimEnd('/')
        }
        return $candidate -and (
            $candidate.Equals(
                '.ai/protocol', [StringComparison]::OrdinalIgnoreCase
            ) -or
            $candidate.StartsWith(
                '.ai/protocol/', [StringComparison]::OrdinalIgnoreCase
            ) -or
            '.ai/protocol'.StartsWith(
                "$candidate/", [StringComparison]::OrdinalIgnoreCase
            )
        )
    })
    if ($reservedRows.Count -eq 0) { return $true }
    $expectedRows = [string[]]@(
        "submodule..ai/protocol.path`n.ai/protocol",
        "submodule..ai/protocol.url`nhttps://github.com/$ProtocolRepository.git"
    )
    [Array]::Sort($expectedRows, [StringComparer]::Ordinal)
    if (($reservedRows -join "`0") -cne ($expectedRows -join "`0")) {
        return $false
    }
    foreach ($property in @('Mode', 'Type', 'Path')) {
        if ($null -eq $ProtocolEntry.PSObject.Properties[$property]) {
            return $false
        }
    }
    return [string]$ProtocolEntry.Mode -ceq '160000' -and
        [string]$ProtocolEntry.Type -ceq 'commit' -and
        [string]$ProtocolEntry.Path -ceq '.ai/protocol'
}

function Test-MeAndAICompletedAdoptionChangeSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Changes,
        [Parameter(Mandatory)][string]$ExpectedAdoptionStrategy,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ProtocolSurfaces,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$TargetPaths,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$FinalEntries
    )

    if ($ExpectedAdoptionStrategy -cnotin @(
        'LegacyUnspecified', 'FreshAdoption', 'FullMigration',
        'HybridReconciliation', 'CleanStart'
    ) -or
        -not (Test-MeAndAIExactOrdinalSequence -Actual $TargetPaths `
            -Expected $script:MeAndAIAdoptionTargetPaths) -or
        -not (Test-MeAndAIUniqueCanonicalPaths -Paths $ProtocolSurfaces) -or
        ($ExpectedAdoptionStrategy -ceq 'LegacyUnspecified' -and
         @($ProtocolSurfaces).Count -ne 0)) {
        return $false
    }
    $surfaceValues = @($ProtocolSurfaces | ForEach-Object { [string]$_ })
    $sortedSurfaces = @($surfaceValues)
    [Array]::Sort($sortedSurfaces, [StringComparer]::Ordinal)
    if (-not (Test-MeAndAIExactOrdinalSequence -Actual $surfaceValues `
        -Expected $sortedSurfaces)) {
        return $false
    }

    $entryMap = [System.Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($entry in @($FinalEntries)) {
        if ($null -eq $entry -or
            $null -eq $entry.PSObject.Properties['Path'] -or
            $null -eq $entry.PSObject.Properties['Exists'] -or
            $null -eq $entry.PSObject.Properties['Mode'] -or
            $entry.Exists -isnot [bool]) {
            return $false
        }
        $path = [string]$entry.Path
        if (-not (Test-MeAndAICanonicalRepositoryPath -Path $path) -or
            $entryMap.ContainsKey($path)) {
            return $false
        }
        $entryMap.Add($path, $entry)
    }

    $normalizedChanges = [System.Collections.Generic.List[object]]::new()
    $changedSet = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($change in @($Changes)) {
        if ($null -eq $change -or
            $null -eq $change.PSObject.Properties['Status'] -or
            $null -eq $change.PSObject.Properties['Path']) {
            return $false
        }
        $status = [string]$change.Status
        $path = [string]$change.Path
        if ($status -cnotin @('A', 'D', 'M', 'T') -or
            -not (Test-MeAndAICanonicalRepositoryPath -Path $path) -or
            -not $changedSet.Add($path)) {
            return $false
        }
        $normalizedChanges.Add([pscustomobject]@{
            Status = $status
            Path = $path
        })
    }
    if ($normalizedChanges.Count -eq 0) { return $false }
    if ($ExpectedAdoptionStrategy -ceq 'HybridReconciliation') {
        $decisionChanges = @($normalizedChanges | Where-Object {
            $path = [string]$_.Path
            [string]$_.Status -cin @('A', 'M') -and
            $path.StartsWith(
                'docs/decisions/', [StringComparison]::Ordinal
            ) -and
            $path.EndsWith(
                '.md', [StringComparison]::Ordinal
            )
        })
        if ($decisionChanges.Count -eq 0) { return $false }
    }

    $requiredSet = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($path in $TargetPaths) { [void]$requiredSet.Add([string]$path) }
    $surfaceSet = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($path in $surfaceValues) { [void]$surfaceSet.Add($path) }
    $sourceEnforcedRequired = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($path in $script:MeAndAISourceEnforcedRequiredPaths) {
        [void]$sourceEnforcedRequired.Add([string]$path)
    }
    $migrationStrategy = $ExpectedAdoptionStrategy -cin @(
        'FullMigration', 'HybridReconciliation', 'CleanStart'
    )
    $manifestDeletions = @($normalizedChanges | Where-Object {
        [string]$_.Status -ceq 'D' -and
        [string]$_.Path -ceq $script:MeAndAIAdoptionManifestPath
    })
    if ($manifestDeletions.Count -ne 1) { return $false }

    foreach ($change in $normalizedChanges) {
        $status = [string]$change.Status
        $path = [string]$change.Path
        $basename = [IO.Path]::GetFileName($path)
        if ($basename.Equals('FG_PAT.txt', [StringComparison]::OrdinalIgnoreCase) -or
            $basename.Equals(
                'MEANDAI_RO_FG_PAT.txt', [StringComparison]::OrdinalIgnoreCase
            ) -or
            $path.Equals(
                $script:MeAndAISeedWorkflowPath,
                [StringComparison]::OrdinalIgnoreCase
            )) {
            return $false
        }
        if ($path -ceq $script:MeAndAIAdoptionManifestPath) {
            if ($status -cne 'D') { return $false }
            continue
        }
        if ($requiredSet.Contains($path)) {
            if ($status -ceq 'D') { return $false }
            continue
        }
        if ($path.StartsWith('.ai/protocol/', [StringComparison]::Ordinal)) {
            if (-not $migrationStrategy -or $status -cne 'D' -or
                -not $surfaceSet.Contains($path)) {
                return $false
            }
            continue
        }
        if ($status -ceq 'A') {
            if (-not (Test-MeAndAIConsumerGovernancePath -Path $path)) {
                return $false
            }
            continue
        }
        if ($status -cin @('M', 'D')) {
            if (-not $migrationStrategy -or -not $surfaceSet.Contains($path) -or
                -not (Test-MeAndAILegacyGovernancePath -Path $path)) {
                return $false
            }
            continue
        }
        return $false
    }

    foreach ($path in $TargetPaths) {
        $value = [string]$path
        if (-not $entryMap.ContainsKey($value)) { return $false }
        $entry = $entryMap[$value]
        $expectedMode = if ($value -ceq '.ai/protocol') {
            '160000'
        }
        else { '100644' }
        if (-not [bool]$entry.Exists -or
            [string]$entry.Mode -cne $expectedMode) {
            return $false
        }
    }
    foreach ($change in @($normalizedChanges | Where-Object {
        [string]$_.Status -cne 'D'
    })) {
        $path = [string]$change.Path
        if ($requiredSet.Contains($path)) { continue }
        if (-not $entryMap.ContainsKey($path)) { return $false }
        $entry = $entryMap[$path]
        $allowedModes = if ($path.StartsWith(
            'tests/meandai-adoption/', [StringComparison]::Ordinal
        )) { @('100644', '100755') } else { @('100644') }
        if (-not [bool]$entry.Exists -or
            [string]$entry.Mode -cnotin $allowedModes) {
            return $false
        }
    }

    foreach ($surface in $surfaceSet) {
        if ($requiredSet.Contains($surface)) {
            $mustChange =
                (Test-MeAndAILegacyCommonAuthorityPath -Path $surface) -or
                ($ExpectedAdoptionStrategy -ceq 'CleanStart' -and
                 -not $sourceEnforcedRequired.Contains($surface))
            if ($mustChange -and -not $changedSet.Contains($surface)) {
                return $false
            }
            continue
        }
        $exists = $entryMap.ContainsKey($surface) -and
            [bool]$entryMap[$surface].Exists
        if ($ExpectedAdoptionStrategy -ceq 'CleanStart' -and $exists -and
            (Test-MeAndAILegacyGovernancePath -Path $surface)) {
            return $false
        }
        if (Test-MeAndAILegacyCommonAuthorityPath -Path $surface) {
            if ($ExpectedAdoptionStrategy -ceq 'FullMigration' -and $exists) {
                return $false
            }
            if ($ExpectedAdoptionStrategy -ceq 'HybridReconciliation' -and
                $exists -and -not $changedSet.Contains($surface)) {
                return $false
            }
        }
    }
    return $true
}

function New-MeAndAICapabilitiesPlan {
    param(
        [string]$State,
        [string]$ProposalMode,
        [object[]]$Collisions,
        [object[]]$Diagnostics,
        [string]$AdoptionStrategy = '',
        [object[]]$ProtocolSurfaces = @(),
        [bool]$ProtocolRecordLossAcknowledged = $false
    )

    return [pscustomobject]@{
        SchemaVersion = 2
        State = $State
        ProposalMode = $ProposalMode
        AdoptionStrategy = $AdoptionStrategy
        ProtocolSurfaces = @($ProtocolSurfaces | ForEach-Object { [string]$_ })
        ProtocolRecordLossAcknowledged = $ProtocolRecordLossAcknowledged
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
        'ExistingProposalValid', 'AdoptionStrategy', 'ProtocolSurfaces',
        'AcknowledgeProtocolRecordLoss'
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
    if ([long]$Snapshot.SchemaVersion -ne 2) {
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

    if ($Snapshot.ProtocolSurfaces -isnot [array] -or
        $Snapshot.AcknowledgeProtocolRecordLoss -isnot [bool]) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @($collisions) `
            -Diagnostics @('Adoption strategy evidence has invalid types.')
    }
    $strategy = Resolve-MeAndAIAdoptionStrategy `
        -RequestedStrategy ([string]$Snapshot.AdoptionStrategy) `
        -ProtocolSurfaces @($Snapshot.ProtocolSurfaces) `
        -Collisions @($collisions) `
        -AcknowledgeProtocolRecordLoss ([bool]$Snapshot.AcknowledgeProtocolRecordLoss)

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
            -Diagnostics @('A deterministic adoption proposal already exists.') `
            -AdoptionStrategy ([string]$strategy.AdoptionStrategy) `
            -ProtocolSurfaces @($strategy.ProtocolSurfaces) `
            -ProtocolRecordLossAcknowledged ([bool]$strategy.ProtocolRecordLossAcknowledged)
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
            -ProposalMode 'None' -Collisions @() -Diagnostics @() `
            -AdoptionStrategy 'ExistingAdoption' `
            -ProtocolSurfaces @($Snapshot.ProtocolSurfaces)
    }

    if ([string]$strategy.State -cne 'Resolved') {
        return New-MeAndAICapabilitiesPlan -State ([string]$strategy.State) `
            -ProposalMode 'None' -Collisions @($collisions) `
            -Diagnostics @($strategy.Diagnostics) `
            -AdoptionStrategy ([string]$strategy.AdoptionStrategy) `
            -ProtocolSurfaces @($strategy.ProtocolSurfaces) `
            -ProtocolRecordLossAcknowledged ([bool]$strategy.ProtocolRecordLossAcknowledged)
    }

    if ($localUpdaterState -ceq 'Partial' -and $collisions.Count -eq 0) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @() `
            -Diagnostics @('A partial updater snapshot must identify its colliding paths.')
    }
    if ($collisions.Count -gt 0) {
        return New-MeAndAICapabilitiesPlan -State 'AdoptionReviewRequired' `
            -ProposalMode 'ManifestOnly' -Collisions @($collisions) -Diagnostics @() `
            -AdoptionStrategy ([string]$strategy.AdoptionStrategy) `
            -ProtocolSurfaces @($strategy.ProtocolSurfaces) `
            -ProtocolRecordLossAcknowledged ([bool]$strategy.ProtocolRecordLossAcknowledged)
    }

    return New-MeAndAICapabilitiesPlan -State 'BootstrapReady' `
        -ProposalMode 'Full' -Collisions @() -Diagnostics @() `
        -AdoptionStrategy ([string]$strategy.AdoptionStrategy) `
        -ProtocolSurfaces @($strategy.ProtocolSurfaces) `
        -ProtocolRecordLossAcknowledged ([bool]$strategy.ProtocolRecordLossAcknowledged)
}

Export-ModuleMember -Function @(
    'Assert-MeAndAIProtocolAssessmentPathCasing',
    'Get-MeAndAIAdoptionProposedPaths',
    'Get-MeAndAIAdoptionTargetPaths',
    'Get-MeAndAIProtocolAssessmentLimits',
    'Get-MeAndAIProtocolSurfaceInventory',
    'Get-MeAndAIRequiredAdoptionTasks',
    'Resolve-MeAndAIAdoptionStrategy',
    'Resolve-MeAndAICapabilitiesLifecycle',
    'Test-MeAndAICompletedAdoptionChangeSet',
    'Test-MeAndAICanonicalRepositoryPath',
    'Test-MeAndAICleanStartSurfaceSupported',
    'Test-MeAndAIConsumerGovernancePath',
    'Test-MeAndAIExactAdoptionPullRequestMarker',
    'Test-MeAndAILegacyCommonAuthorityPath',
    'Test-MeAndAILegacyGovernancePath',
    'Test-MeAndAIProtocolAssessmentRelevantPath',
    'Test-MeAndAIExactAdoptionManifest',
    'Test-MeAndAIReservedProtocolSubmoduleContract'
)
