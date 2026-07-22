[CmdletBinding()]
param(
    [ValidateSet('All', 'Contracts', 'VerticalSlices')]
    [string]$Shard = 'All'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
$modulePath = Join-Path $root 'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
$adapterPath = Join-Path $root 'templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1'
$workflowPath = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
$launcherPath = Join-Path $root `
    'scripts/quick-adoption/Public/Invoke-MeAndAIQuickAdoption.ps1'
$dispatchPath = Join-Path $root `
    'scripts/quick-adoption/Private/ProposalOwnership.ps1'
$adoptionPath = Join-Path $root 'docs/adoption.md'
$protocolPath = Join-Path $root 'PROTOCOL.md'
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -ne $Actual) {
        Add-Failure "$Message; expected '$Expected', found '$Actual'"
    }
}

function Get-Test0153GitBlobSha {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $header = [Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
    $payload = [byte[]]::new($header.Length + $Bytes.Length)
    [Array]::Copy($header, 0, $payload, 0, $header.Length)
    [Array]::Copy($Bytes, 0, $payload, $header.Length, $Bytes.Length)
    $sha = [Security.Cryptography.SHA1]::Create()
    try {
        return ([BitConverter]::ToString(
            $sha.ComputeHash($payload)
        )).Replace('-', '').ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

foreach ($path in @(
    $modulePath, $adapterPath, $workflowPath, $launcherPath, $dispatchPath,
    $adoptionPath, $protocolPath
)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "TEST-0027 missing lifecycle asset: $path"
    }
}

if (Test-Path -LiteralPath $modulePath -PathType Leaf) {
    Import-Module $modulePath -Force

    function Invoke-LifecyclePlan {
        param(
            [string]$LocalUpdaterState = 'Absent',
            [string]$SeedWorkflowState = 'Exact',
            [string[]]$Collisions = @(),
            [string]$AdoptionStrategy = 'Auto',
            [string[]]$ProtocolSurfaces = @(),
            [bool]$AcknowledgeProtocolRecordLoss = $false,
            [bool]$ManifestExists = $false,
            [bool]$RemoteBranchExists = $false,
            [int]$OpenPullRequestCount = 0,
            [bool]$ExistingProposalValid = $false
        )

        Resolve-MeAndAICapabilitiesLifecycle -Snapshot ([pscustomobject]@{
            SchemaVersion = 2
            LocalUpdaterState = $LocalUpdaterState
            SeedWorkflowState = $SeedWorkflowState
            Collisions = @($Collisions)
            AdoptionStrategy = $AdoptionStrategy
            ProtocolSurfaces = @($ProtocolSurfaces)
            AcknowledgeProtocolRecordLoss = $AcknowledgeProtocolRecordLoss
            ManifestExists = $ManifestExists
            RemoteBranchExists = $RemoteBranchExists
            OpenPullRequestCount = $OpenPullRequestCount
            ExistingProposalValid = $ExistingProposalValid
        })
    }

    $plan = Invoke-LifecyclePlan -LocalUpdaterState 'Complete'
    Assert-Equal 'Update' $plan.State 'TEST-0027 complete local updater should own the update path'
    Assert-Equal 'None' $plan.ProposalMode 'TEST-0027 update path must not create an adoption proposal'

    $plan = Invoke-LifecyclePlan
    Assert-Equal 'BootstrapReady' $plan.State 'TEST-0028 collision-free seed should bootstrap'
    Assert-Equal 'Full' $plan.ProposalMode 'TEST-0028 collision-free seed should propose full core assets'
    Assert-Equal 'FreshAdoption' $plan.AdoptionStrategy 'TEST-0127 Auto should resolve a clean tree to FreshAdoption'
    if ([long]$plan.SchemaVersion -ne 2 -or
        $null -ne $plan.PSObject.Properties['SourceGraph']) {
        Add-Failure 'TEST-0153 legacy schema-2 lifecycle compatibility changed when graph evidence was absent.'
    }

    $plan = Invoke-LifecyclePlan -Collisions @('.gitmodules')
    Assert-Equal 'AdoptionReviewRequired' $plan.State 'TEST-0127 a generic target collision should require semantic review without inventing prior protocol evidence'
    Assert-Equal 'FreshAdoption' $plan.AdoptionStrategy 'TEST-0127 Auto should retain FreshAdoption for a protocol-free generic collision'

    $plan = Invoke-LifecyclePlan -ProtocolSurfaces @('ai/WORK_INDEX.md')
    Assert-Equal 'ProtocolMigrationReviewRequired' $plan.State 'TEST-0127 Auto with protocol evidence should require maintainer selection'
    Assert-Equal 'None' $plan.ProposalMode 'TEST-0127 unresolved strategy must not create a proposal'

    $plan = Invoke-LifecyclePlan -ProtocolSurfaces @('ai/WORK_INDEX.md') `
        -AdoptionStrategy 'FreshAdoption'
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0127 explicit FreshAdoption must reject protocol evidence'

    $plan = Invoke-LifecyclePlan -ProtocolSurfaces @('ai/WORK_INDEX.md') `
        -AdoptionStrategy 'FullMigration'
    Assert-Equal 'BootstrapReady' $plan.State 'TEST-0127 explicit FullMigration should authorize a collision-free proposal'
    Assert-Equal 'FullMigration' $plan.AdoptionStrategy 'TEST-0127 resolved strategy should remain exact'

    foreach ($unsupportedEvidenceFreeStrategy in @(
        'FullMigration', 'HybridReconciliation', 'CleanStart'
    )) {
        $plan = Invoke-LifecyclePlan `
            -Collisions @('.github/PULL_REQUEST_TEMPLATE.md') `
            -AdoptionStrategy $unsupportedEvidenceFreeStrategy `
            -AcknowledgeProtocolRecordLoss `
                ($unsupportedEvidenceFreeStrategy -ceq 'CleanStart')
        Assert-Equal 'BlockedManualReview' $plan.State "TEST-0127 $unsupportedEvidenceFreeStrategy must reject an evidence-free repository"
    }

    $plan = Invoke-LifecyclePlan -ProtocolSurfaces @('ai/WORK_INDEX.md') `
        -AdoptionStrategy 'CleanStart'
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0127 CleanStart without loss acknowledgement must block'

    $plan = Invoke-LifecyclePlan -ProtocolSurfaces @('ai/WORK_INDEX.md') `
        -AdoptionStrategy 'CleanStart' -AcknowledgeProtocolRecordLoss $true
    Assert-Equal 'BootstrapReady' $plan.State 'TEST-0127 acknowledged CleanStart should authorize a proposal'

    $plan = Invoke-LifecyclePlan -ProtocolSurfaces @('.ai/protocol/legacy.md') `
        -AdoptionStrategy 'CleanStart' -AcknowledgeProtocolRecordLoss $true
    Assert-Equal 'BootstrapReady' $plan.State 'TEST-0127 acknowledged CleanStart should allow exact legacy protocol-root records'

    $plan = Invoke-LifecyclePlan -ProtocolSurfaces @('.cursor/rules') `
        -AdoptionStrategy 'CleanStart' -AcknowledgeProtocolRecordLoss $true
    Assert-Equal 'BootstrapReady' $plan.State 'TEST-0127 acknowledged CleanStart should allow an exact active-rule root'

    $plan = Invoke-LifecyclePlan `
        -ProtocolSurfaces @('.github/instructions/api.instructions.md') `
        -AdoptionStrategy 'CleanStart' -AcknowledgeProtocolRecordLoss $true
    Assert-Equal 'BootstrapReady' $plan.State 'TEST-0127 acknowledged CleanStart should allow path-specific GitHub Copilot instructions'

    $plan = Invoke-LifecyclePlan `
        -ProtocolSurfaces @('.ai/meandai-update-state.json')
    Assert-Equal 'ProtocolMigrationReviewRequired' $plan.State 'TEST-0127 a pre-existing protocol ledger must not be classified as fresh'

    $plan = Invoke-LifecyclePlan -ProtocolSurfaces @('RELEASES.md') `
        -AdoptionStrategy 'CleanStart' -AcknowledgeProtocolRecordLoss $true
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0127 CleanStart must reject ambiguous product-or-governance records before proposal mutation'

    $plan = Invoke-LifecyclePlan -ProtocolSurfaces @('ai/WORK_INDEX.md') `
        -AdoptionStrategy 'Abort'
    Assert-Equal 'Aborted' $plan.State 'TEST-0127 Abort should produce an explicit no-mutation state'
    Assert-Equal 'None' $plan.ProposalMode 'TEST-0127 Abort must not create a proposal'

    $plan = Invoke-LifecyclePlan -LocalUpdaterState 'Partial' -Collisions @(
        '.github/scripts/MeAndAI.ProtocolUpdate.psm1'
    ) -ProtocolSurfaces @(
        '.github/scripts/MeAndAI.ProtocolUpdate.psm1'
    ) -AdoptionStrategy 'HybridReconciliation'
    Assert-Equal 'AdoptionReviewRequired' $plan.State 'TEST-0027 partial updater must not execute as complete'
    Assert-Equal 'ManifestOnly' $plan.ProposalMode 'TEST-0030 partial adoption should preserve existing targets'

    $plan = Invoke-LifecyclePlan -Collisions @('AGENTS.md', '.gitmodules') `
        -ProtocolSurfaces @('AGENTS.md') `
        -AdoptionStrategy 'FullMigration'
    Assert-Equal 'AdoptionReviewRequired' $plan.State 'TEST-0030 collisions should require semantic review'
    Assert-Equal 'AGENTS.md,.gitmodules' (@($plan.Collisions) -join ',') 'TEST-0030 collision paths should remain exact and deterministic'

    $plan = Invoke-LifecyclePlan -RemoteBranchExists $true -OpenPullRequestCount 1 `
        -ExistingProposalValid $true
    Assert-Equal 'PendingAdoption' $plan.State 'TEST-0031 one pending adoption proposal should remain idempotent'
    Assert-Equal 'None' $plan.ProposalMode 'TEST-0031 pending work must not be replaced'
    Assert-Equal 'FreshAdoption' $plan.AdoptionStrategy 'TEST-0130 pending work should retain its validated strategy identity'

    $plan = Invoke-LifecyclePlan -RemoteBranchExists $true -OpenPullRequestCount 1
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0047 an unverified existing proposal must block'

    $plan = Invoke-LifecyclePlan -RemoteBranchExists $true
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0031 orphan adoption branch must block'

    $plan = Invoke-LifecyclePlan -OpenPullRequestCount 1
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0031 PR without deterministic branch must block'

    $plan = Invoke-LifecyclePlan -ManifestExists $true
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0031 existing manifest ownership must block'

    $plan = Invoke-LifecyclePlan -SeedWorkflowState 'Drifted'
    Assert-Equal 'BlockedManualReview' $plan.State 'TEST-0031 seed workflow drift must block remote execution'

    $manifestValidator = Get-Command -Name 'Test-MeAndAIExactAdoptionManifest' `
        -CommandType Function -ErrorAction SilentlyContinue
    $surfaceClassifier = Get-Command -Name 'Get-MeAndAIProtocolSurfaceInventory' `
        -CommandType Function -ErrorAction SilentlyContinue
    $assessmentLimitGetter = Get-Command `
        -Name 'Get-MeAndAIProtocolAssessmentLimits' `
        -CommandType Function -ErrorAction SilentlyContinue
    $strategyResolver = Get-Command -Name 'Resolve-MeAndAIAdoptionStrategy' `
        -CommandType Function -ErrorAction SilentlyContinue
    $relevantPathClassifier = Get-Command `
        -Name 'Test-MeAndAIProtocolAssessmentRelevantPath' `
        -CommandType Function -ErrorAction SilentlyContinue
    $pathCasingAssertion = Get-Command `
        -Name 'Assert-MeAndAIProtocolAssessmentPathCasing' `
        -CommandType Function -ErrorAction SilentlyContinue
    $canonicalPathValidator = Get-Command `
        -Name 'Test-MeAndAICanonicalRepositoryPath' `
        -CommandType Function -ErrorAction SilentlyContinue
    $legacyGovernanceClassifier = Get-Command `
        -Name 'Test-MeAndAILegacyGovernancePath' `
        -CommandType Function -ErrorAction SilentlyContinue
    $legacyCommonAuthorityClassifier = Get-Command `
        -Name 'Test-MeAndAILegacyCommonAuthorityPath' `
        -CommandType Function -ErrorAction SilentlyContinue
    $consumerGovernanceClassifier = Get-Command `
        -Name 'Test-MeAndAIConsumerGovernancePath' `
        -CommandType Function -ErrorAction SilentlyContinue
    $cleanStartClassifier = Get-Command `
        -Name 'Test-MeAndAICleanStartSurfaceSupported' `
        -CommandType Function -ErrorAction SilentlyContinue
    $proposalMarkerValidator = Get-Command `
        -Name 'Test-MeAndAIExactAdoptionPullRequestMarker' `
        -CommandType Function -ErrorAction SilentlyContinue
    $completedChangeValidator = Get-Command `
        -Name 'Test-MeAndAICompletedAdoptionChangeSet' `
        -CommandType Function -ErrorAction SilentlyContinue
    $instructionGraphBuilder = Get-Command `
        -Name 'New-MeAndAIInstructionGraph' `
        -CommandType Function -ErrorAction SilentlyContinue
    $instructionGraphValidator = Get-Command `
        -Name 'Test-MeAndAIExactInstructionGraph' `
        -CommandType Function -ErrorAction SilentlyContinue
    $instructionGraphLimitGetter = Get-Command `
        -Name 'Get-MeAndAIInstructionGraphLimits' `
        -CommandType Function -ErrorAction SilentlyContinue
    $instructionGraphRecordConverter = Get-Command `
        -Name 'ConvertTo-MeAndAIInstructionGraphRecord' `
        -CommandType Function -ErrorAction SilentlyContinue
    $instructionGraphIdentityGetter = Get-Command `
        -Name 'Get-MeAndAIInstructionGraphIdentity' `
        -CommandType Function -ErrorAction SilentlyContinue
    $instructionGraphIdentityValidator = Get-Command `
        -Name 'Test-MeAndAIExactInstructionGraphIdentity' `
        -CommandType Function -ErrorAction SilentlyContinue
    $instructionGraphIdentityRecordValidator = Get-Command `
        -Name 'Test-MeAndAIExactInstructionGraphIdentityRecord' `
        -CommandType Function -ErrorAction SilentlyContinue
    $reservedSubmoduleValidator = Get-Command `
        -Name 'Test-MeAndAIReservedProtocolSubmoduleContract' `
        -CommandType Function -ErrorAction SilentlyContinue
    $targetPathGetter = Get-Command -Name 'Get-MeAndAIAdoptionTargetPaths' `
        -CommandType Function -ErrorAction SilentlyContinue
    $proposedPathGetter = Get-Command -Name 'Get-MeAndAIAdoptionProposedPaths' `
        -CommandType Function -ErrorAction SilentlyContinue
    if ($null -eq $manifestValidator -or $null -eq $targetPathGetter -or
        $null -eq $proposedPathGetter -or $null -eq $surfaceClassifier -or
        $null -eq $assessmentLimitGetter -or $null -eq $strategyResolver -or
        $null -eq $relevantPathClassifier -or
        $null -eq $pathCasingAssertion -or $null -eq $canonicalPathValidator -or
        $null -eq $legacyGovernanceClassifier -or
         $null -eq $legacyCommonAuthorityClassifier -or
         $null -eq $consumerGovernanceClassifier -or
         $null -eq $cleanStartClassifier -or
         $null -eq $proposalMarkerValidator -or
         $null -eq $completedChangeValidator -or
         $null -eq $reservedSubmoduleValidator) {
        Add-Failure 'TEST-0080/TEST-0127 pure lifecycle module does not export the canonical adoption path, assessment, strategy, inventory, and manifest contract.'
    }
    if ($null -eq $instructionGraphBuilder -or
        $null -eq $instructionGraphValidator -or
        $null -eq $instructionGraphLimitGetter -or
        $null -eq $instructionGraphRecordConverter -or
        $null -eq $instructionGraphIdentityGetter -or
        $null -eq $instructionGraphIdentityValidator -or
        $null -eq $instructionGraphIdentityRecordValidator) {
        Add-Failure 'TEST-0153 pure lifecycle module does not export exact instruction-graph identity contracts.'
    }
    else {
        $protocolSha = ('a' * 40) -join ''
        $graphBase = ('b' * 40)
        $graphText =
            'Required reading: [protocol](.ai/protocol/PROTOCOL.md).'
        [byte[]]$graphBytes = [Text.UTF8Encoding]::new($false).GetBytes(
            $graphText
        )
        $graphBlobs = @{ 'AGENTS.md' = $graphBytes }
        $graphEntries = @(
            [pscustomobject]@{
                Path = '.ai/protocol'
                Mode = '160000'
                Type = 'commit'
                Sha = $protocolSha
            },
            [pscustomobject]@{
                Path = 'AGENTS.md'
                Mode = '100644'
                Type = 'blob'
                Sha = Get-Test0153GitBlobSha -Bytes $graphBytes
            }
        )
        $graphReader = {
            param($entry)
            $path = [string]$entry.Path
            if (-not $graphBlobs.ContainsKey($path)) {
                throw "TEST-0153 attempted to dereference '$path'."
            }
            return ,([byte[]]$graphBlobs[$path])
        }.GetNewClosure()
        $sourceGraph = & $instructionGraphBuilder -BaseHead $graphBase `
            -TreeEntries $graphEntries -ReadBlob $graphReader
        $sourceGraphRecord = & $instructionGraphRecordConverter `
            -Graph $sourceGraph
        $sourceGraphIdentity = & $instructionGraphIdentityGetter `
            -Graph $sourceGraph
        if (-not (& $instructionGraphValidator -Graph $sourceGraph) -or
            -not (& $instructionGraphIdentityRecordValidator `
                -Identity $sourceGraphIdentity) -or
            -not (& $instructionGraphIdentityValidator `
                -Identity $sourceGraphIdentity -Graph $sourceGraphRecord)) {
            Add-Failure 'TEST-0153 the small exact graph did not satisfy the exported graph and identity contracts.'
        }
        $graphPlan = Resolve-MeAndAICapabilitiesLifecycle `
            -Snapshot ([pscustomobject]@{
                SchemaVersion = 3
                LocalUpdaterState = 'Absent'
                SeedWorkflowState = 'Exact'
                Collisions = @()
                AdoptionStrategy = 'FullMigration'
                ProtocolSurfaces = @($sourceGraph.protocolSurfaces)
                AcknowledgeProtocolRecordLoss = $false
                ManifestExists = $false
                RemoteBranchExists = $false
                OpenPullRequestCount = 0
                ExistingProposalValid = $false
                SourceGraph = $sourceGraph
            })
        if ([long]$graphPlan.SchemaVersion -ne 3 -or
            [string]$graphPlan.State -cne 'BootstrapReady' -or
            $null -eq $graphPlan.PSObject.Properties['SourceGraph'] -or
            -not (& $instructionGraphIdentityValidator `
                -Identity (& $instructionGraphIdentityGetter `
                    -Graph $graphPlan.SourceGraph) `
                -Graph $sourceGraph)) {
            Add-Failure 'TEST-0153 schema-3 lifecycle did not retain the exact source-graph identity.'
        }
        $surfaceDriftPlan = Resolve-MeAndAICapabilitiesLifecycle `
            -Snapshot ([pscustomobject]@{
                SchemaVersion = 3
                LocalUpdaterState = 'Absent'
                SeedWorkflowState = 'Exact'
                Collisions = @()
                AdoptionStrategy = 'FullMigration'
                ProtocolSurfaces = @('AGENTS.md')
                AcknowledgeProtocolRecordLoss = $false
                ManifestExists = $false
                RemoteBranchExists = $false
                OpenPullRequestCount = 0
                ExistingProposalValid = $false
                SourceGraph = $sourceGraph
            })
        Assert-Equal 'BlockedManualReview' $surfaceDriftPlan.State `
            'TEST-0153 schema-3 lifecycle accepted a surface projection that differs from its source graph'

        $expectedCollisions = @('AGENTS.md')
        $expectedTargetPaths = @(
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
        $expectedProposedPaths = @(
            '.github/workflows/meandai-protocol-update.yml'
        ) + @($expectedTargetPaths)
        $actualTargetPaths = @(& $targetPathGetter)
        $actualProposedPaths = @(& $proposedPathGetter)
        if (($actualTargetPaths -join "`n") -cne ($expectedTargetPaths -join "`n")) {
            Add-Failure 'TEST-0080 canonical adoption target path inventory is not exact.'
        }
        if (($actualProposedPaths -join "`n") -cne ($expectedProposedPaths -join "`n")) {
            Add-Failure 'TEST-0080 canonical adoption proposed path inventory is not exact.'
        }
        $assessmentLimits = & $assessmentLimitGetter
        if ($null -eq $assessmentLimits -or
            $assessmentLimits.MaximumSurfaceCount -isnot [int] -or
            [int]$assessmentLimits.MaximumSurfaceCount -ne 256 -or
            $assessmentLimits.MaximumSurfaceUtf8Bytes -isnot [int] -or
            [int]$assessmentLimits.MaximumSurfaceUtf8Bytes -ne 16384) {
            Add-Failure 'TEST-0127 module-owned assessment limits are missing or noncanonical.'
        }
        $moduleRecognizedPath = 'docs/findings/FIND-9999-wrapper-prefilter.md'
        if (-not (& $relevantPathClassifier -Path $moduleRecognizedPath `
                -TargetPaths $actualTargetPaths) -or
            (& $relevantPathClassifier -Path 'src/app.ps1' `
                -TargetPaths $actualTargetPaths)) {
            Add-Failure 'TEST-0127 module-owned streaming assessment predicate did not distinguish a recognized governance surface from application content.'
        }
        $moduleRecognizedInventory = @(& $surfaceClassifier -Paths @(
            'src/app.ps1', $moduleRecognizedPath
        ))
        foreach ($emptyInventoryInput in @(
            [pscustomobject]@{ Name = 'scalar null'; Paths = $null },
            [pscustomobject]@{ Name = 'empty array'; Paths = [object[]]@() },
            [pscustomobject]@{
                Name = 'PowerShell 7 singleton-null sentinel'
                Paths = [object[]]@($null)
            }
        )) {
            try {
                $emptyInventory = @(& $surfaceClassifier `
                    -Paths $emptyInventoryInput.Paths)
                if ($emptyInventory.Count -ne 0) {
                    Add-Failure "TEST-0127 $($emptyInventoryInput.Name) did not produce an empty protocol inventory."
                }
            }
            catch {
                Add-Failure "TEST-0127 $($emptyInventoryInput.Name) was not accepted as an empty protocol inventory: $($_.Exception.Message)"
            }
        }
        if ($moduleRecognizedInventory.Count -ne 1 -or
            [string]$moduleRecognizedInventory[0] -cne $moduleRecognizedPath) {
            Add-Failure 'TEST-0127 module-owned relevant-path predicate and surface inventory disagree.'
        }
        $mixedNullInventoryFailed = $false
        try {
            [void]@(& $surfaceClassifier -Paths ([object[]]@(
                'AGENTS.md', $null
            )))
        }
        catch {
            $mixedNullInventoryFailed = $true
        }
        if (-not $mixedNullInventoryFailed) {
            Add-Failure 'TEST-0127 a null mixed with a real protocol path was silently ignored.'
        }
        $casingFailed = $false
        $canonicalCasingOutput = @(& $pathCasingAssertion `
            -Path '.github/workflows/meandai-protocol-update.yml')
        try {
            & $pathCasingAssertion -Path 'agents.md'
        }
        catch {
            $casingFailed = $_.Exception.Message -like '*noncanonical casing*'
        }
        if ($canonicalCasingOutput.Count -ne 0 -or -not $casingFailed -or
            -not (& $canonicalPathValidator -Path $moduleRecognizedPath) -or
            (& $canonicalPathValidator -Path '../AGENTS.md')) {
            Add-Failure 'TEST-0127 module-owned canonical path and adoption casing policy did not fail closed.'
        }
        if (-not (& $legacyGovernanceClassifier `
                -Path 'docs/governance/legacy.md') -or
            -not (& $legacyGovernanceClassifier -Path 'nested/AGENTS.md') -or
            (& $legacyGovernanceClassifier -Path 'docs/features/FEAT-9999.md') -or
            -not (& $legacyCommonAuthorityClassifier `
                -Path '.github/instructions/api.instructions.md') -or
            (& $legacyCommonAuthorityClassifier -Path 'ai/WORK_INDEX.md') -or
            -not (& $consumerGovernanceClassifier `
                -Path 'docs/features/FEAT-9999.md') -or
            (& $consumerGovernanceClassifier -Path 'docs/features/FEAT-9999.json') -or
            (& $consumerGovernanceClassifier -Path 'src/app.ps1') -or
            -not (& $cleanStartClassifier -Path 'docs/ideas/README.md') -or
            (& $cleanStartClassifier -Path 'docs/features/FEAT-9999.md')) {
            Add-Failure 'TEST-0127 module-owned legacy authority and CleanStart classifiers do not preserve their policy boundaries.'
        }
        $requiredTasks = @(
            'Create or reconcile the repository labels required by the protocol.',
            'Create project-owned feature and decision records for adoption.',
            'Apply the manifest-selected adoption strategy; do not infer or change it.',
            'Tailor project-local memory without importing protocol-repository facts.',
            'Resolve every collision through semantic review; do not overwrite blindly.',
            'Create and run the project test evidence required by DoR and DoD.',
            'Verify all documentation links and traceability references.',
            'Remove the manifest before marking the pull request ready or merging it.'
        )
        $expectedProtocolSurfaces = @(
            '.ai/meandai-update-state.json', '.ai/protocol/legacy.md',
            '.cursor/rules', '.github/instructions/api.instructions.md',
            'AGENTS.md', 'ai/DECISIONS.md', 'ai/WORK_INDEX.md'
        )
        $classifiedSurfaces = @(& $surfaceClassifier -Paths @(
            'src/app.ps1', 'ai/WORK_INDEX.md', 'AGENTS.md',
            '.github/workflows/build.yml', 'ai/DECISIONS.md', 'ai/model.py',
            '.ai/protocol/legacy.md', '.ai/meandai-update-state.json',
            '.cursor/rules', '.github/instructions/api.instructions.md'
        ))
        if (($classifiedSurfaces -join ',') -cne ($expectedProtocolSurfaces -join ',')) {
            Add-Failure "TEST-0127 bounded protocol-surface inventory was not unique and deterministic: $($classifiedSurfaces -join ',')"
        }
        foreach ($invalidInventory in @(
            @('../AGENTS.md'),
            @('/AGENTS.md'),
            @('ai/file.md', 'AI/FILE.md')
        )) {
            $inventoryFailed = $false
            try {
                [void]@(& $surfaceClassifier -Paths $invalidInventory)
            }
            catch {
                $inventoryFailed = $true
            }
            if (-not $inventoryFailed) {
                Add-Failure "TEST-0127 invalid or ambiguous inventory was accepted: $($invalidInventory -join ',')"
            }
        }
        foreach ($invalidStrategyInput in @(
            [pscustomobject]@{
                ProtocolSurfaces = @('../AGENTS.md')
                Collisions = @()
            },
            [pscustomobject]@{
                ProtocolSurfaces = @()
                Collisions = @('/AGENTS.md')
            }
        )) {
            $invalidStrategy = & $strategyResolver `
                -RequestedStrategy 'FullMigration' `
                -ProtocolSurfaces @($invalidStrategyInput.ProtocolSurfaces) `
                -Collisions @($invalidStrategyInput.Collisions) `
                -AcknowledgeProtocolRecordLoss $false
            if ([string]$invalidStrategy.State -cne 'BlockedManualReview') {
                Add-Failure 'TEST-0127 the pure strategy resolver accepted a noncanonical protocol surface or collision path.'
            }
        }
        $oversizedInventory = @(0..256 | ForEach-Object {
            "docs/governance/record-$_.md"
        })
        $oversizedFailed = $false
        try {
            [void]@(& $surfaceClassifier -Paths $oversizedInventory)
        }
        catch {
            $oversizedFailed = $true
        }
        if (-not $oversizedFailed) {
            Add-Failure 'TEST-0127 oversized protocol inventory did not fail closed.'
        }

        $validManifest = [pscustomobject][ordered]@{
            schema = 2
            operation = 'ai-capabilities-adoption'
            state = 'AdoptionReviewRequired'
            repository = 'owner/consumer'
            targetTag = 'v0.9.7'
            protocolSha = $protocolSha
            adoptionStrategy = 'HybridReconciliation'
            protocolSurfaces = $expectedProtocolSurfaces
            protocolRecordLossAcknowledged = $false
            collisions = $expectedCollisions
            proposedPaths = $expectedProposedPaths
            requiredTasks = $requiredTasks
        }
        function Test-ManifestFixture {
            param([Parameter(Mandatory)]$Manifest)

            return Test-MeAndAIExactAdoptionManifest -Manifest $Manifest `
                -Repository 'owner/consumer' -TargetTag 'v0.9.7' `
                -ProtocolSha $protocolSha -ExpectedState 'AdoptionReviewRequired' `
                -ExpectedAdoptionStrategy 'HybridReconciliation' `
                -ExpectedProtocolSurfaces $expectedProtocolSurfaces `
                -ExpectedProtocolRecordLossAcknowledgement $false `
                -ExpectedCollisions $expectedCollisions
        }

        if (-not (Test-ManifestFixture -Manifest $validManifest)) {
            Add-Failure 'TEST-0080 exact canonical adoption manifest was rejected.'
        }

        $invalidManifests = [ordered]@{}
        $extraProperty = $validManifest | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $extraProperty | Add-Member -NotePropertyName unexpected -NotePropertyValue $true
        $invalidManifests['additional property'] = $extraProperty
        $missingProperty = $validManifest | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $missingProperty.PSObject.Properties.Remove('requiredTasks')
        $invalidManifests['missing property'] = $missingProperty
        $wrongTasks = $validManifest | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $wrongTasks.requiredTasks = @('Remove the manifest before readiness.')
        $invalidManifests['wrong required task inventory'] = $wrongTasks
        $wrongPaths = $validManifest | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $wrongPaths.proposedPaths = @($expectedProposedPaths | Select-Object -Skip 1)
        $invalidManifests['wrong proposed path inventory'] = $wrongPaths
        $wrongCollisions = $validManifest | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $wrongCollisions.collisions = @('docs/ideas/README.md')
        $invalidManifests['wrong collision inventory'] = $wrongCollisions
        $wrongStrategy = $validManifest | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $wrongStrategy.adoptionStrategy = 'FullMigration'
        $invalidManifests['wrong adoption strategy'] = $wrongStrategy
        $wrongSurfaces = $validManifest | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $wrongSurfaces.protocolSurfaces = @('AGENTS.md')
        $invalidManifests['wrong protocol surface inventory'] = $wrongSurfaces
        $invalidManifests['array root type'] = [object[]]@(
            $validManifest,
            $validManifest
        )
        foreach ($identityVariant in @(
            @{ Name = 'repository identity'; Property = 'repository'; Value = 'other/consumer' },
            @{ Name = 'target-tag identity'; Property = 'targetTag'; Value = 'v0.8.4' },
            @{ Name = 'protocol-SHA identity'; Property = 'protocolSha'; Value = ('b' * 40) },
            @{ Name = 'state identity'; Property = 'state'; Value = 'BootstrapReady' },
            @{ Name = 'operation identity'; Property = 'operation'; Value = 'other-operation' },
            @{ Name = 'schema value'; Property = 'schema'; Value = 1 },
            @{ Name = 'schema type'; Property = 'schema'; Value = '2' },
            @{ Name = 'collision property type'; Property = 'collisions'; Value = 'AGENTS.md' }
        )) {
            $variant = $validManifest | ConvertTo-Json -Depth 5 | ConvertFrom-Json
            $variant.($identityVariant.Property) = $identityVariant.Value
            $invalidManifests[$identityVariant.Name] = $variant
        }

        foreach ($entry in $invalidManifests.GetEnumerator()) {
            if (Test-ManifestFixture -Manifest $entry.Value) {
                Add-Failure "TEST-0080 manifest with $($entry.Key) was accepted."
            }
        }

        $graphManifest = [pscustomobject][ordered]@{
            schema = 3
            operation = 'ai-capabilities-adoption'
            state = 'BootstrapReady'
            repository = 'owner/consumer'
            targetTag = 'v0.9.7'
            protocolSha = $protocolSha
            adoptionStrategy = 'FullMigration'
            protocolSurfaces = @($sourceGraph.protocolSurfaces)
            protocolRecordLossAcknowledged = $false
            collisions = @()
            proposedPaths = $expectedProposedPaths
            requiredTasks = $requiredTasks
            sourceGraph = $sourceGraphRecord
        }
        function Test-GraphManifestFixture {
            param([Parameter(Mandatory)]$Manifest)

            return Test-MeAndAIExactAdoptionManifest -Manifest $Manifest `
                -Repository 'owner/consumer' -TargetTag 'v0.9.7' `
                -ProtocolSha $protocolSha -ExpectedState 'BootstrapReady' `
                -ExpectedAdoptionStrategy 'FullMigration' `
                -ExpectedProtocolSurfaces @($sourceGraph.protocolSurfaces) `
                -ExpectedProtocolRecordLossAcknowledgement $false `
                -ExpectedCollisions @() -ExpectedSourceGraph $sourceGraph
        }
        if (-not (Test-GraphManifestFixture -Manifest $graphManifest)) {
            Add-Failure 'TEST-0153 exact schema-3 graph manifest was rejected.'
        }
        if (Test-MeAndAIExactAdoptionManifest -Manifest $validManifest `
                -Repository 'owner/consumer' -TargetTag 'v0.9.7' `
                -ProtocolSha $protocolSha `
                -ExpectedState 'AdoptionReviewRequired' `
                -ExpectedAdoptionStrategy 'HybridReconciliation' `
                -ExpectedProtocolSurfaces $expectedProtocolSurfaces `
                -ExpectedProtocolRecordLossAcknowledgement $false `
                -ExpectedCollisions $expectedCollisions `
                -ExpectedSourceGraph $sourceGraph) {
            Add-Failure 'TEST-0153 graph-aware manifest validation retroactively accepted legacy schema-2 evidence.'
        }
        $graphManifestVariants = [ordered]@{}
        $manifestDigestDrift = $graphManifest | ConvertTo-Json -Depth 30 |
            ConvertFrom-Json
        $manifestDigestDrift.sourceGraph.digest = ('f' * 64)
        $graphManifestVariants['digest drift'] = $manifestDigestDrift
        $manifestCountDrift = $graphManifest | ConvertTo-Json -Depth 30 |
            ConvertFrom-Json
        $manifestCountDrift.sourceGraph.counts.nodes =
            [long]$manifestCountDrift.sourceGraph.counts.nodes + 1
        $graphManifestVariants['count drift'] = $manifestCountDrift
        $manifestLimitDrift = $graphManifest | ConvertTo-Json -Depth 30 |
            ConvertFrom-Json
        $manifestLimitDrift.sourceGraph.limits.maximumNodes =
            [long]$manifestLimitDrift.sourceGraph.limits.maximumNodes - 1
        $graphManifestVariants['limit drift'] = $manifestLimitDrift
        $manifestSurfaceDrift = $graphManifest | ConvertTo-Json -Depth 30 |
            ConvertFrom-Json
        $manifestSurfaceDrift.protocolSurfaces = @('AGENTS.md')
        $graphManifestVariants['surface drift'] = $manifestSurfaceDrift
        foreach ($entry in $graphManifestVariants.GetEnumerator()) {
            if (Test-GraphManifestFixture -Manifest $entry.Value) {
                Add-Failure "TEST-0153 schema-3 manifest accepted $($entry.Key)."
            }
        }

        $proposalHead = ('c' * 40)
        $proposalMarker = [ordered]@{
            schema = 5
            phase = 'Proposed'
            state = 'BootstrapReady'
            target = 'v0.9.7'
            protocolSha = $protocolSha
            head = $proposalHead
            adoptionStrategy = 'FreshAdoption'
            protocolSurfaces = @()
            protocolRecordLossAcknowledged = $false
            repository = 'owner/consumer'
            actor = 'owner'
        } | ConvertTo-Json -Compress
        $validPullRequest = [pscustomobject][ordered]@{
            number = 40
            url = 'https://github.com/owner/consumer/pull/40'
            headRefName = 'automation/meandai-capabilities-v0.9.7'
            headRefOid = $proposalHead
            baseRefName = 'main'
            headRepository = [pscustomobject]@{ nameWithOwner = 'owner/consumer' }
            author = [pscustomobject]@{ login = 'owner' }
            body = "<!-- meandai-capabilities-adoption:$proposalMarker -->"
            isDraft = $true
            state = 'OPEN'
        }
        $markerParameters = @{
            RemoteHead = $proposalHead
            Repository = 'owner/consumer'
            Branch = 'automation/meandai-capabilities-v0.9.7'
            BaseBranch = 'main'
            TargetTag = 'v0.9.7'
            TargetSha = $protocolSha
            ExpectedActor = 'owner'
            ExpectedState = 'BootstrapReady'
            ExpectedAdoptionStrategy = 'FreshAdoption'
            ExpectedProtocolSurfaces = @()
            ExpectedProtocolRecordLossAcknowledgement = $false
            ExpectedPhase = 'Proposed'
        }
        if (-not (& $proposalMarkerValidator -PullRequest $validPullRequest `
                @markerParameters)) {
            Add-Failure 'TEST-0145 production-owned proposal marker contract rejected canonical evidence.'
        }
        foreach ($markerVariant in @(
            [pscustomobject]@{ Name = 'non-draft proposal'; Mutate = {
                param($value) $value.isDraft = $false
            } },
            [pscustomobject]@{ Name = 'moved head'; Mutate = {
                param($value) $value.headRefOid = ('d' * 40)
            } },
            [pscustomobject]@{ Name = 'untrusted author'; Mutate = {
                param($value) $value.author.login = 'untrusted-actor'
            } },
            [pscustomobject]@{ Name = 'duplicate marker'; Mutate = {
                param($value) $value.body += "`n$value.body"
            } }
        )) {
            $variant = $validPullRequest | ConvertTo-Json -Depth 8 |
                ConvertFrom-Json
            & $markerVariant.Mutate $variant
            if (& $proposalMarkerValidator -PullRequest $variant `
                    @markerParameters) {
                Add-Failure "TEST-0145 production-owned proposal marker contract accepted $($markerVariant.Name)."
            }
        }
        $legacyPullRequest = $validPullRequest | ConvertTo-Json -Depth 8 |
            ConvertFrom-Json
        $legacyMarker = [ordered]@{
            schema = 2
            state = 'BootstrapReady'
            target = 'v0.9.7'
            protocolSha = $protocolSha
            head = $proposalHead
            repository = 'owner/consumer'
            actor = 'owner'
        } | ConvertTo-Json -Compress
        $legacyPullRequest.body =
            "<!-- meandai-capabilities-adoption:$legacyMarker -->"
        $legacyMarkerParameters = @{}
        foreach ($entry in $markerParameters.GetEnumerator()) {
            $legacyMarkerParameters[$entry.Key] = $entry.Value
        }
        $legacyMarkerParameters.ExpectedAdoptionStrategy = 'LegacyUnspecified'
        if (-not (& $proposalMarkerValidator `
                -PullRequest $legacyPullRequest @legacyMarkerParameters)) {
            Add-Failure 'TEST-0145 production marker contract rejected legacy schema-2 proposal evidence.'
        }
        $legacyMarkerParameters.ExpectedProtocolSurfaces = @('AGENTS.md')
        if (& $proposalMarkerValidator `
                -PullRequest $legacyPullRequest @legacyMarkerParameters) {
            Add-Failure 'TEST-0145 production marker contract accepted protocol surfaces for legacy schema-2 evidence.'
        }
        $graphAwareLegacyMarkerParameters = @{}
        foreach ($entry in $markerParameters.GetEnumerator()) {
            $graphAwareLegacyMarkerParameters[$entry.Key] = $entry.Value
        }
        $graphAwareLegacyMarkerParameters.ExpectedSourceGraph = $sourceGraph
        if (& $proposalMarkerValidator -PullRequest $validPullRequest `
                @graphAwareLegacyMarkerParameters) {
            Add-Failure 'TEST-0153 graph-aware marker validation retroactively accepted schema-5 evidence.'
        }

        $graphMarker = [pscustomobject][ordered]@{
            schema = 7
            phase = 'Proposed'
            state = 'BootstrapReady'
            target = 'v0.9.7'
            protocolSha = $protocolSha
            head = $proposalHead
            branch = 'automation/meandai-capabilities-v0.9.7'
            adoptionStrategy = 'FullMigration'
            protocolSurfaces = @($sourceGraphIdentity.protocolSurfaces)
            protocolRecordLossAcknowledged = $false
            graphBase = [string]$sourceGraphIdentity.graphBase
            graphDigest = [string]$sourceGraphIdentity.graphDigest
            graphCounts = $sourceGraphIdentity.graphCounts
            graphLimits = $sourceGraphIdentity.graphLimits
            repository = 'owner/consumer'
            actor = 'owner'
        }
        $graphPullRequest = $validPullRequest | ConvertTo-Json -Depth 30 |
            ConvertFrom-Json
        $graphPullRequest.body = '<!-- meandai-capabilities-adoption:' +
            ($graphMarker | ConvertTo-Json -Depth 30 -Compress) + ' -->'
        $graphMarkerParameters = @{
            RemoteHead = $proposalHead
            Repository = 'owner/consumer'
            Branch = 'automation/meandai-capabilities-v0.9.7'
            BaseBranch = 'main'
            TargetTag = 'v0.9.7'
            TargetSha = $protocolSha
            ExpectedActor = 'owner'
            ExpectedState = 'BootstrapReady'
            ExpectedAdoptionStrategy = 'FullMigration'
            ExpectedProtocolSurfaces = @($sourceGraph.protocolSurfaces)
            ExpectedProtocolRecordLossAcknowledgement = $false
            ExpectedSourceGraph = $sourceGraph
            ExpectedPhase = 'Proposed'
        }
        if (-not (& $proposalMarkerValidator `
                -PullRequest $graphPullRequest @graphMarkerParameters)) {
            Add-Failure 'TEST-0153 schema-7 Proposed marker rejected exact graph evidence.'
        }

        $completedGraphMarker = $graphMarker | ConvertTo-Json -Depth 30 |
            ConvertFrom-Json
        $completedGraphMarker.phase = 'Completed'
        $completedGraphPullRequest = $graphPullRequest |
            ConvertTo-Json -Depth 30 | ConvertFrom-Json
        $completedGraphPullRequest.isDraft = $false
        $completedGraphPullRequest.body =
            '<!-- meandai-capabilities-adoption:' +
            ($completedGraphMarker | ConvertTo-Json -Depth 30 -Compress) +
            ' -->'
        $completedGraphMarkerParameters = @{}
        foreach ($entry in $graphMarkerParameters.GetEnumerator()) {
            if ($entry.Key -cne 'ExpectedSourceGraph') {
                $completedGraphMarkerParameters[$entry.Key] = $entry.Value
            }
        }
        $completedGraphMarkerParameters.ExpectedSourceGraphIdentity =
            $sourceGraphIdentity
        $completedGraphMarkerParameters.ExpectedPhase = 'Completed'
        if (-not (& $proposalMarkerValidator `
                -PullRequest $completedGraphPullRequest `
                @completedGraphMarkerParameters)) {
            Add-Failure 'TEST-0153 schema-7 Completed marker rejected exact graph-identity evidence.'
        }

        $graphMarkerVariants = [ordered]@{}
        $markerDigestDrift = $graphMarker | ConvertTo-Json -Depth 30 |
            ConvertFrom-Json
        $markerDigestDrift.graphDigest = ('f' * 64)
        $graphMarkerVariants['digest drift'] = $markerDigestDrift
        $markerCountDrift = $graphMarker | ConvertTo-Json -Depth 30 |
            ConvertFrom-Json
        $markerCountDrift.graphCounts.nodes =
            [long]$markerCountDrift.graphCounts.nodes + 1
        $graphMarkerVariants['count drift'] = $markerCountDrift
        $markerLimitDrift = $graphMarker | ConvertTo-Json -Depth 30 |
            ConvertFrom-Json
        $markerLimitDrift.graphLimits.maximumNodes =
            [long]$markerLimitDrift.graphLimits.maximumNodes - 1
        $graphMarkerVariants['limit drift'] = $markerLimitDrift
        $markerSurfaceDrift = $graphMarker | ConvertTo-Json -Depth 30 |
            ConvertFrom-Json
        $markerSurfaceDrift.protocolSurfaces = @('AGENTS.md')
        $graphMarkerVariants['surface drift'] = $markerSurfaceDrift
        foreach ($entry in $graphMarkerVariants.GetEnumerator()) {
            $variantPullRequest = $graphPullRequest |
                ConvertTo-Json -Depth 30 | ConvertFrom-Json
            $variantPullRequest.body =
                '<!-- meandai-capabilities-adoption:' +
                ($entry.Value | ConvertTo-Json -Depth 30 -Compress) +
                ' -->'
            if (& $proposalMarkerValidator -PullRequest $variantPullRequest `
                    @graphMarkerParameters) {
                Add-Failure "TEST-0153 schema-7 marker accepted $($entry.Key)."
            }
        }

        $protocolEntry = [pscustomobject]@{
            Mode = '160000'; Type = 'commit'; Sha = $protocolSha
            Path = '.ai/protocol'
        }
        $canonicalSubmoduleRows = @(
            "submodule..ai/protocol.path`n.ai/protocol",
            "submodule..ai/protocol.url`nhttps://github.com/hasanmanzak/meAndAI.git"
        )
        if (-not (& $reservedSubmoduleValidator -Rows $canonicalSubmoduleRows `
                -ProtocolEntry $protocolEntry `
                -ProtocolRepository 'hasanmanzak/meAndAI')) {
            Add-Failure 'TEST-0145 production-owned reserved-submodule contract rejected canonical rows.'
        }
        $canonicalRowsWithUnrelatedEmptyValue = @(
            $canonicalSubmoduleRows
            "submodule.product.ignore`n"
        )
        if (-not (& $reservedSubmoduleValidator `
                -Rows $canonicalRowsWithUnrelatedEmptyValue `
                -ProtocolEntry $protocolEntry `
                -ProtocolRepository 'hasanmanzak/meAndAI')) {
            Add-Failure 'TEST-0145 production-owned reserved-submodule contract rejected an unrelated empty configuration value.'
        }
        foreach ($reservedVariant in @(
            [pscustomobject]@{
                Name = 'alias exact path'
                Rows = @(
                    "submodule.consumer-alias.path`n.ai/protocol",
                    "submodule.consumer-alias.url`nhttps://example.invalid/product.git"
                )
            },
            [pscustomobject]@{
                Name = 'case variant'
                Rows = @(
                    "submodule..AI/Protocol.path`n.AI/Protocol",
                    "submodule..AI/Protocol.url`nhttps://example.invalid/product.git"
                )
            },
            [pscustomobject]@{
                Name = 'ancestor path'
                Rows = @(
                    "submodule.consumer-alias.path`n.ai",
                    "submodule.consumer-alias.url`nhttps://example.invalid/product.git"
                )
            },
            [pscustomobject]@{
                Name = 'descendant path'
                Rows = @(
                    "submodule.consumer-alias.path`n.ai/protocol/vendor",
                    "submodule.consumer-alias.url`nhttps://example.invalid/product.git"
                )
            }
        )) {
            if (& $reservedSubmoduleValidator -Rows $reservedVariant.Rows `
                    -ProtocolEntry ([pscustomobject]@{
                        Mode = ''; Type = ''; Sha = ''; Path = ''
                    }) -ProtocolRepository 'hasanmanzak/meAndAI') {
                Add-Failure "TEST-0145 production-owned reserved-submodule contract accepted $($reservedVariant.Name)."
            }
        }

        $completionEntries = @($actualTargetPaths | ForEach-Object {
            [pscustomobject]@{
                Path = [string]$_
                Exists = $true
                Mode = if ([string]$_ -ceq '.ai/protocol') {
                    '160000'
                }
                else { '100644' }
            }
        }) + @([pscustomobject]@{
            Path = 'docs/governance/adoption-complete.md'
            Exists = $true
            Mode = '100644'
        })
        $freshCompletionChanges = @(
            [pscustomobject]@{
                Status = 'D'; Path = '.ai/adoption/meandai-capabilities.json'
            },
            [pscustomobject]@{
                Status = 'A'; Path = 'docs/governance/adoption-complete.md'
            }
        )
        $completionParameters = @{
            ExpectedAdoptionStrategy = 'FreshAdoption'
            ProtocolSurfaces = @()
            TargetPaths = $actualTargetPaths
            FinalEntries = $completionEntries
        }
        if (-not (& $completedChangeValidator `
                -Changes $freshCompletionChanges @completionParameters)) {
            Add-Failure 'TEST-0145 production-owned completion contract rejected the canonical FreshAdoption change set.'
        }
        if (-not (& $completedChangeValidator `
                -Changes $freshCompletionChanges `
                -ExpectedAdoptionStrategy 'LegacyUnspecified' `
                -ProtocolSurfaces @() -TargetPaths $actualTargetPaths `
                -FinalEntries $completionEntries)) {
            Add-Failure 'TEST-0145 production-owned completion contract rejected a canonical legacy change set.'
        }
        if (& $completedChangeValidator `
                -Changes @(
                    $freshCompletionChanges + [pscustomobject]@{
                        Status = 'M'; Path = 'AGENTS.md'
                    }
                ) -ExpectedAdoptionStrategy 'HybridReconciliation' `
                -ProtocolSurfaces @('AGENTS.md') `
                -TargetPaths $actualTargetPaths `
                -FinalEntries $completionEntries) {
            Add-Failure 'TEST-0145 production-owned completion contract accepted HybridReconciliation without a changed decision record.'
        }
        $nullFinalEntriesAccepted = $false
        $nullFinalEntriesError = ''
        try {
            $nullFinalEntriesAccepted = [bool](& $completedChangeValidator `
                -Changes $freshCompletionChanges `
                -ExpectedAdoptionStrategy 'FreshAdoption' `
                -ProtocolSurfaces @() -TargetPaths $actualTargetPaths `
                -FinalEntries $null)
        }
        catch {
            $nullFinalEntriesError = $_.Exception.Message
        }
        if ($nullFinalEntriesError -or $nullFinalEntriesAccepted) {
            Add-Failure "TEST-0145 production-owned completion contract did not fail closed for null-equivalent empty final-entry evidence: $nullFinalEntriesError"
        }
        foreach ($invalidCompletion in @(
            [pscustomobject]@{
                Name = 'credential addition'
                Change = [pscustomobject]@{ Status = 'A'; Path = 'FG_PAT.txt' }
            },
            [pscustomobject]@{
                Name = 'credential case variant'
                Change = [pscustomobject]@{ Status = 'A'; Path = 'fg_pat.txt' }
            },
            [pscustomobject]@{
                Name = 'nested credential'
                Change = [pscustomobject]@{ Status = 'A'; Path = 'secrets/FG_PAT.txt' }
            },
            [pscustomobject]@{
                Name = 'protected workflow modification'
                Change = [pscustomobject]@{
                    Status = 'M'
                    Path = '.github/workflows/meandai-protocol-update.yml'
                }
            },
            [pscustomobject]@{
                Name = 'manifest retention'
                Change = [pscustomobject]@{
                    Status = 'M'
                    Path = '.ai/adoption/meandai-capabilities.json'
                }
            },
            [pscustomobject]@{
                Name = 'application addition'
                Change = [pscustomobject]@{ Status = 'A'; Path = 'src/new.txt' }
            },
            [pscustomobject]@{
                Name = 'application modification'
                Change = [pscustomobject]@{ Status = 'M'; Path = 'src/app.txt' }
            },
            [pscustomobject]@{
                Name = 'application deletion'
                Change = [pscustomobject]@{ Status = 'D'; Path = 'src/app.txt' }
            }
        )) {
            $changes = if ($invalidCompletion.Name -ceq 'manifest retention') {
                @($invalidCompletion.Change, $freshCompletionChanges[1])
            }
            else { @($freshCompletionChanges + $invalidCompletion.Change) }
            if (& $completedChangeValidator -Changes $changes `
                    @completionParameters) {
                Add-Failure "TEST-0145 production-owned completion contract accepted $($invalidCompletion.Name)."
            }
        }

        $strategyEntries = @($completionEntries) + @(
            [pscustomobject]@{
                Path = 'CLAUDE.md'; Exists = $false; Mode = ''
            },
            [pscustomobject]@{
                Path = '.cursor/rules/consumer.mdc'; Exists = $false; Mode = ''
            },
            [pscustomobject]@{
                Path = '.windsurf/rules/consumer.md'; Exists = $true; Mode = '100644'
            }
        )
        $validFullChanges = @(
            $freshCompletionChanges[0],
            $freshCompletionChanges[1],
            [pscustomobject]@{ Status = 'M'; Path = 'AGENTS.md' },
            [pscustomobject]@{ Status = 'D'; Path = 'CLAUDE.md' }
        )
        if (-not (& $completedChangeValidator -Changes $validFullChanges `
                -ExpectedAdoptionStrategy 'FullMigration' `
                -ProtocolSurfaces @('AGENTS.md', 'CLAUDE.md') `
                -TargetPaths $actualTargetPaths -FinalEntries $strategyEntries)) {
            Add-Failure 'TEST-0145 production-owned completion contract rejected canonical FullMigration changes.'
        }
        $completedContractVariants = @(
            [pscustomobject]@{
                Name = 'completed-fullmigration-bootstrap-ready'
                Strategy = 'FullMigration'
                CommonStatus = 'D'
                ExtraPaths = @()
                ExtraStatus = @()
            },
            [pscustomobject]@{
                Name = 'completed-fullmigration-cursor-rule'
                Strategy = 'FullMigration'
                CommonStatus = 'D'
                ExtraPaths = @('.cursor/rules/consumer.mdc')
                ExtraStatus = @('D')
            },
            [pscustomobject]@{
                Name = 'completed-hybrid-windsurf-rule'
                Strategy = 'HybridReconciliation'
                CommonStatus = 'M'
                ExtraPaths = @('.windsurf/rules/consumer.md')
                ExtraStatus = @('M')
            },
            [pscustomobject]@{
                Name = 'completed-fullmigration-cursor-root-gitlink'
                Strategy = 'FullMigration'
                CommonStatus = 'D'
                ExtraPaths = @('.cursor/rules')
                ExtraStatus = @('D')
            },
            [pscustomobject]@{
                Name = 'completed-cleanstart-cursor-root-gitlink'
                Strategy = 'CleanStart'
                CommonStatus = 'D'
                ExtraPaths = @('.cursor/rules')
                ExtraStatus = @('D')
            },
            [pscustomobject]@{
                Name = 'completed-fullmigration-github-instructions-root-gitlink'
                Strategy = 'FullMigration'
                CommonStatus = 'D'
                ExtraPaths = @('.github/instructions')
                ExtraStatus = @('D')
            },
            [pscustomobject]@{
                Name = 'completed-hybrid-github-instructions-descendant'
                Strategy = 'HybridReconciliation'
                CommonStatus = 'M'
                ExtraPaths = @('.github/instructions/foo.instructions.md')
                ExtraStatus = @('M')
            },
            [pscustomobject]@{
                Name = 'completed-cleanstart-github-instructions-root-gitlink'
                Strategy = 'CleanStart'
                CommonStatus = 'D'
                ExtraPaths = @('.github/instructions')
                ExtraStatus = @('D')
            },
            [pscustomobject]@{
                Name = 'completed-fullmigration-nested-protocol-surfaces'
                Strategy = 'FullMigration'
                CommonStatus = 'D'
                ExtraPaths = @(
                    '.ai/protocol/legacy-a.md',
                    '.ai/protocol/legacy-b.md'
                )
                ExtraStatus = @('D', 'D')
            }
        )
        foreach ($contractVariant in $completedContractVariants) {
            $variantSurfaces = @(
                @('AGENTS.md', 'CLAUDE.md') +
                @($contractVariant.ExtraPaths)
            )
            [Array]::Sort($variantSurfaces, [StringComparer]::Ordinal)
            $variantChanges = [System.Collections.Generic.List[object]]::new()
            foreach ($change in $freshCompletionChanges) {
                $variantChanges.Add($change)
            }
            $variantChanges.Add([pscustomobject]@{
                Status = 'M'; Path = 'AGENTS.md'
            })
            $variantChanges.Add([pscustomobject]@{
                Status = [string]$contractVariant.CommonStatus
                Path = 'CLAUDE.md'
            })
            $variantEntries = [System.Collections.Generic.List[object]]::new()
            foreach ($entry in $completionEntries) {
                $variantEntries.Add($entry)
            }
            $commonExists = [string]$contractVariant.CommonStatus -cne 'D'
            $variantEntries.Add([pscustomobject]@{
                Path = 'CLAUDE.md'
                Exists = [bool]$commonExists
                Mode = if ($commonExists) { '100644' } else { '' }
            })
            for ($variantIndex = 0;
                 $variantIndex -lt @($contractVariant.ExtraPaths).Count;
                 $variantIndex++) {
                $status = [string]$contractVariant.ExtraStatus[$variantIndex]
                $path = [string]$contractVariant.ExtraPaths[$variantIndex]
                $variantChanges.Add([pscustomobject]@{
                    Status = $status; Path = $path
                })
                $exists = $status -cne 'D'
                $variantEntries.Add([pscustomobject]@{
                    Path = $path
                    Exists = [bool]$exists
                    Mode = if ($exists) { '100644' } else { '' }
                })
            }
            if ([string]$contractVariant.Strategy -ceq
                'HybridReconciliation') {
                $variantChanges.Add([pscustomobject]@{
                    Status = 'A'
                    Path = 'docs/decisions/DEC-fixture.md'
                })
                $variantEntries.Add([pscustomobject]@{
                    Path = 'docs/decisions/DEC-fixture.md'
                    Exists = $true
                    Mode = '100644'
                })
            }
            if (-not (& $completedChangeValidator `
                    -Changes @($variantChanges) `
                    -ExpectedAdoptionStrategy `
                        ([string]$contractVariant.Strategy) `
                    -ProtocolSurfaces $variantSurfaces `
                    -TargetPaths $actualTargetPaths `
                    -FinalEntries @($variantEntries))) {
                Add-Failure "TEST-0145 production completion contract rejected '$($contractVariant.Name)'."
            }
        }
        $retainedCommonEntries = @($strategyEntries | ForEach-Object {
            if ([string]$_.Path -ceq 'CLAUDE.md') {
                [pscustomobject]@{ Path = 'CLAUDE.md'; Exists = $true; Mode = '100644' }
            }
            else { $_ }
        })
        if (& $completedChangeValidator `
                -Changes @($freshCompletionChanges + [pscustomobject]@{
                    Status = 'M'; Path = 'AGENTS.md'
                }) -ExpectedAdoptionStrategy 'FullMigration' `
                -ProtocolSurfaces @('AGENTS.md', 'CLAUDE.md') `
                -TargetPaths $actualTargetPaths `
                -FinalEntries $retainedCommonEntries) {
            Add-Failure 'TEST-0145 FullMigration retained a common authority surface.'
        }
        if (& $completedChangeValidator -Changes @(
                $freshCompletionChanges,
                [pscustomobject]@{ Status = 'M'; Path = 'CLAUDE.md' }
            ) -ExpectedAdoptionStrategy 'HybridReconciliation' `
                -ProtocolSurfaces @('AGENTS.md', 'CLAUDE.md') `
                -TargetPaths $actualTargetPaths `
                -FinalEntries (@($retainedCommonEntries))) {
            Add-Failure 'TEST-0145 HybridReconciliation accepted an unchanged required authority surface.'
        }
        if (& $completedChangeValidator -Changes @(
                $freshCompletionChanges,
                [pscustomobject]@{
                    Status = 'D'; Path = '.ai/protocol/legacy-b.md'
                }
            ) -ExpectedAdoptionStrategy 'FullMigration' `
                -ProtocolSurfaces @('.ai/protocol/legacy-a.md') `
                -TargetPaths $actualTargetPaths `
                -FinalEntries $completionEntries) {
            Add-Failure 'TEST-0145 completion contract accepted an undeclared nested protocol deletion.'
        }
    }
}

if (Test-Path -LiteralPath $workflowPath -PathType Leaf) {
    $workflow = Get-Content -LiteralPath $workflowPath -Raw
    foreach ($required in @(
        'BOOTSTRAP_PROTOCOL_TAG: v0.12.6',
        'run-name: meAndAI AI capabilities lifecycle [${{ inputs.correlation_id || github.event_name }}]',
        'correlation_id:',
        'adoption_strategy:',
        'acknowledge_protocol_record_loss:',
        'Verify immutable protocol release',
        "'X-GitHub-Api-Version' = '2026-03-10'",
        'immutable',
        'published_at',
        'ref: ${{ env.BOOTSTRAP_PROTOCOL_TAG }}',
        'MeAndAI.ProtocolUpdate.psm1',
        'Invoke-MeAndAIProtocolUpdate.ps1',
        'Invoke-MeAndAICapabilitiesBootstrap.ps1',
        'Local updater installation is partial',
        'MEANDAI_UPDATER_TOKEN',
        'MEANDAI_PROTOCOL_TOKEN',
        'PROTOCOL_TOKEN: ${{ secrets.MEANDAI_PROTOCOL_TOKEN || github.token }}'
    )) {
        if (-not $workflow.Contains($required)) {
            Add-Failure "TEST-0027 workflow is missing '$required'"
        }
    }
    foreach ($forbidden in @('pull_request_target:', 'gh pr merge', 'actions/checkout@v')) {
        if ($workflow.Contains($forbidden)) {
            Add-Failure "TEST-0032 workflow contains forbidden behavior '$forbidden'"
        }
    }
    $proposalJobStart = $workflow.IndexOf('  propose-update:', [StringComparison]::Ordinal)
    $finalizerJobStart = $workflow.IndexOf('  finalize-managed-merge:', [StringComparison]::Ordinal)
    if ($proposalJobStart -lt 0 -or $finalizerJobStart -le $proposalJobStart -or
        -not $workflow.Substring(
            $proposalJobStart, $finalizerJobStart - $proposalJobStart
        ).Contains('issues: write') -or
        -not $workflow.Substring(
            $proposalJobStart, $finalizerJobStart - $proposalJobStart
        ).Contains('ISSUE_TOKEN: ${{ github.token }}')) {
        Add-Failure 'TEST-0111 proposal issue authority is not isolated to the job-scoped token.'
    }
    $trustedPreflightIndex = $workflow.IndexOf('-ValidateLocalUpdaterOnly', [StringComparison]::Ordinal)
    $localUpdaterInvocationIndex = $workflow.IndexOf('& "./$adapterPath"', [StringComparison]::Ordinal)
    if ($trustedPreflightIndex -lt 0 -or $localUpdaterInvocationIndex -lt 0 -or
        $trustedPreflightIndex -ge $localUpdaterInvocationIndex) {
        Add-Failure 'TEST-0077 trusted-source updater validation must run before the local updater adapter.'
    }
    foreach ($requiredStrategyBoundary in @(
        "if (`$env:EVENT_NAME -cne 'workflow_dispatch')",
        'Initial adoption waits for a launcher-owned or explicit manual dispatch with an adoption strategy.',
        '-AdoptionStrategy $env:ADOPTION_STRATEGY',
        '-AcknowledgeProtocolRecordLoss'
    )) {
        if (-not $workflow.Contains($requiredStrategyBoundary)) {
            Add-Failure "TEST-0128 workflow initial-adoption strategy gate is missing '$requiredStrategyBoundary'."
        }
    }
    foreach ($requiredGraphHandoff in @(
        'source_graph_identity:',
        "SOURCE_GRAPH_IDENTITY: `${{ inputs.source_graph_identity || '' }}",
        'if ([bool]$env:EXPECTED_BASE_SHA -ne',
        '[bool]$env:SOURCE_GRAPH_IDENTITY)',
        '-SourceGraphIdentityJson $env:SOURCE_GRAPH_IDENTITY'
    )) {
        if (-not $workflow.Contains($requiredGraphHandoff)) {
            Add-Failure "TEST-0153 workflow source-graph handoff is missing '$requiredGraphHandoff'."
        }
    }
    foreach ($requiredEventBinding in @(
        'ref: ${{ github.sha }}',
        'EVENT_SHA: ${{ github.sha }}',
        "EXPECTED_BASE_SHA: `${{ inputs.expected_base_sha || '' }}",
        '$checkedOutHead = (& git rev-parse HEAD) -join ''''',
        '$checkedOutHead -cne $env:EVENT_SHA',
        '$env:EVENT_SHA -cne $env:EXPECTED_BASE_SHA',
        '$defaultRef = "refs/heads/$env:DEFAULT_BRANCH"',
        '$env:EVENT_REF -cne $defaultRef',
        '& git ls-remote --heads origin $defaultRef',
        '[string]$Matches.sha -cne $env:EVENT_SHA'
    )) {
        if (-not $workflow.Contains($requiredEventBinding)) {
            Add-Failure "TEST-0128 workflow immutable event/base binding is missing '$requiredEventBinding'."
        }
    }
    $eventCheckoutIndex = $workflow.IndexOf(
        '$checkedOutHead = (& git rev-parse HEAD)', [StringComparison]::Ordinal
    )
    $liveDefaultIndex = $workflow.IndexOf(
        '& git ls-remote --heads origin $defaultRef', [StringComparison]::Ordinal
    )
    $bootstrapInvocationIndex = $workflow.IndexOf(
        '& "./$bootstrap" -TargetTag', [StringComparison]::Ordinal
    )
    if ($eventCheckoutIndex -lt 0 -or $liveDefaultIndex -le $eventCheckoutIndex -or
        $bootstrapInvocationIndex -le $liveDefaultIndex) {
        Add-Failure 'TEST-0128 workflow must bind the checked-out event and live default head before bootstrap mutation.'
    }
}

if (Test-Path -LiteralPath $modulePath -PathType Leaf) {
    $module = Get-Content -LiteralPath $modulePath -Raw
    foreach ($forbidden in @('Invoke-Native', 'Invoke-RestMethod', 'Invoke-WebRequest', "& git", "& gh")) {
        if ($module.Contains($forbidden)) {
            Add-Failure "TEST-0030 pure lifecycle planner contains live-operation token '$forbidden'"
        }
    }
}

if (Test-Path -LiteralPath $adapterPath -PathType Leaf) {
    $adapter = Get-Content -LiteralPath $adapterPath -Raw
    foreach ($required in @(
        '.ai/adoption/meandai-capabilities.json',
        'Resolve-MeAndAICapabilitiesLifecycle',
        '--force-with-lease=',
        'Assert-LiveConsumerDefaultBranch -ExpectedBranch $env:DEFAULT_BRANCH',
        '--force-with-lease=${ref}:$headSha',
        'the exact unpublished proposal branch was removed',
        'the exact draft and proposal branch were removed',
        "'pr', 'create'",
        '--draft',
        'BootstrapReady',
        'AdoptionReviewRequired',
        'PendingAdoption',
        'ProtocolMigrationReviewRequired',
        'AdoptionStrategy',
        'ProtocolSurfaces',
        'Get-MeAndAIProtocolAssessmentLimits',
        'Test-MeAndAIProtocolAssessmentRelevantPath -Path $path',
        'Assert-MeAndAIProtocolAssessmentPathCasing -Path $path',
        'Test-MeAndAIExactAdoptionPullRequestMarker',
        'Test-MeAndAICompletedAdoptionChangeSet',
        'Test-MeAndAIReservedProtocolSubmoduleContract',
        'BlockedManualReview',
        'ValidateLocalUpdaterOnly'
    )) {
        if (-not $adapter.Contains($required)) {
            Add-Failure "TEST-0028 bootstrap adapter is missing '$required'"
        }
    }
    foreach ($forbidden in @("'issue', 'create'", "'label', 'create'", "'pr', 'merge'")) {
        if ($adapter.Contains($forbidden)) {
            Add-Failure "TEST-0032 bootstrap adapter contains forbidden mutation '$forbidden'"
        }
    }
    foreach ($duplicatedPolicy in @(
        '$AssessmentSurfaceFiles', '$AssessmentSurfaceRoots',
        '$AssessmentMaximumSurfaceCount',
        '$LegacyCommonAuthorityFiles', '$LegacyAiGovernanceFiles',
        'function Test-AssessmentRelevantPath',
        'function Test-CompletedLegacyGovernancePath',
        'function Test-CompletedLegacyCommonAuthorityPath',
        'function Test-ExactCanonicalSurfaceSequence',
        'Test-MeAndAIConsumerGovernancePath -Path $Path',
        'Test-MeAndAILegacyGovernancePath -Path $path',
        'Test-MeAndAILegacyCommonAuthorityPath -Path $surface'
    )) {
        if ($adapter.Contains($duplicatedPolicy)) {
            Add-Failure "TEST-0127 bootstrap adapter duplicates module-owned assessment policy '$duplicatedPolicy'."
        }
    }
    foreach ($requiredGraphBoundary in @(
        'SourceGraphIdentityJson',
        'Get-InstructionGraphForCommit -Repository $workspace',
        'Test-MeAndAIExactInstructionGraphIdentity',
        'The workflow event is not one exact child of the assessed instruction-graph base.',
        'The independently rebuilt instruction graph does not match the launcher-authorized identity.'
    )) {
        if (-not $adapter.Contains($requiredGraphBoundary)) {
            Add-Failure "TEST-0153 hosted adapter source-graph boundary is missing '$requiredGraphBoundary'."
        }
    }
    $graphRebuildIndex = $adapter.IndexOf(
        'Get-InstructionGraphForCommit -Repository $workspace',
        [StringComparison]::Ordinal
    )
    $proposalBranchIndex = $adapter.IndexOf(
        '$branch = "$BranchPrefix$TargetTag"',
        [StringComparison]::Ordinal
    )
    if ($graphRebuildIndex -lt 0 -or $proposalBranchIndex -le $graphRebuildIndex) {
        Add-Failure 'TEST-0153 hosted adapter must rebuild and validate the authorized graph before resolving proposal mutation state.'
    }
}

if ((Test-Path -LiteralPath $launcherPath -PathType Leaf) -and
    (Test-Path -LiteralPath $dispatchPath -PathType Leaf)) {
    $launcher = Get-Content -LiteralPath $launcherPath -Raw
    $dispatch = Get-Content -LiteralPath $dispatchPath -Raw
    foreach ($requiredLauncherHandoff in @(
        '$dispatchSourceGraph = $preflightAssessment.InstructionGraph',
        'Get-MeAndAIInstructionGraphIdentity',
        '$dispatchSourceGraphIdentityJson',
        '-SourceGraphIdentityJson $dispatchSourceGraphIdentityJson'
    )) {
        if (-not $launcher.Contains($requiredLauncherHandoff)) {
            Add-Failure "TEST-0153 quick-adoption launcher graph handoff is missing '$requiredLauncherHandoff'."
        }
    }
    foreach ($requiredDispatchHandoff in @(
        '[string]$SourceGraphIdentityJson',
        '--field', 'source_graph_identity=$SourceGraphIdentityJson'
    )) {
        if (-not $dispatch.Contains($requiredDispatchHandoff)) {
            Add-Failure "TEST-0153 lifecycle dispatch graph handoff is missing '$requiredDispatchHandoff'."
        }
    }
}

if (Test-Path -LiteralPath $adoptionPath -PathType Leaf) {
    $adoption = Get-Content -LiteralPath $adoptionPath -Raw
    foreach ($required in @(
        'AI capabilities lifecycle',
        'BootstrapReady',
        'AdoptionReviewRequired',
        'PendingAdoption',
        '.ai/adoption/meandai-capabilities.json',
        'does not start an AI agent',
        'remove the manifest'
    )) {
        if (-not $adoption.Contains($required)) {
            Add-Failure "TEST-0032 adoption contract is missing '$required'"
        }
    }
}

if (Test-Path -LiteralPath $protocolPath -PathType Leaf) {
    $protocol = Get-Content -LiteralPath $protocolPath -Raw
    foreach ($required in @(
        'AI-capabilities lifecycle',
        'deterministic adoption discovery',
        'transient handoff manifest',
        'MUST NOT imply that an AI agent is running'
    )) {
        if (-not $protocol.Contains($required)) {
            Add-Failure "TEST-0032 protocol lifecycle contract is missing '$required'"
        }
    }
}

$adapterTestPath = Join-Path $root 'tests/capabilities/initial-adoption/capabilities-bootstrap-adapter.fixture.ps1'
$dispatchTestPath = Join-Path $root `
    'tests/capabilities/initial-adoption/source-graph-dispatch.fixture.ps1'
$graphIdentityTestPath = Join-Path $root `
    'tests/capabilities/initial-adoption/capabilities-bootstrap-graph-identity.fixture.ps1'
$graphDriftTestPath = Join-Path $root `
    'tests/capabilities/initial-adoption/capabilities-bootstrap-adapter-drift.fixture.ps1'
if (-not (Test-Path -LiteralPath $adapterTestPath -PathType Leaf)) {
    Add-Failure 'TEST-0028 missing bootstrap adapter integration tests.'
}
elseif (-not (Test-Path -LiteralPath $dispatchTestPath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $graphIdentityTestPath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $graphDriftTestPath -PathType Leaf)) {
    Add-Failure 'TEST-0153 missing source-graph dispatch or hosted-adapter integration fixture.'
}
elseif ($failures.Count -eq 0 -and $Shard -cin @('All', 'VerticalSlices')) {
    $engine = (Get-Process -Id $PID).Path
    & $engine -NoProfile -ExecutionPolicy Bypass -File $dispatchTestPath
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    & $engine -NoProfile -ExecutionPolicy Bypass -File $adapterTestPath
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

if ($failures.Count -gt 0) {
    Write-Host "AI capabilities lifecycle tests failed with $($failures.Count) problem(s):" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'AI capabilities lifecycle tests passed for all declared scenarios in this suite.' -ForegroundColor Green
if ($Shard -ceq 'All') {
    $scenarioResult = New-MeAndAIScenarioResult `
        -Owner 'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1' `
        -SourcePaths @(
            $PSCommandPath, $adapterTestPath, $dispatchTestPath,
            $graphIdentityTestPath, $graphDriftTestPath
        ) `
        -AuthorityPath $scenarioAuthorityPath
    Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
}
else {
    Write-Host "AI capabilities lifecycle shard '$Shard' passed." -ForegroundColor Green
}
