[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/MeAndAI.ScenarioEvidence.psm1') -Force
$modulePath = Join-Path $root 'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
$adapterPath = Join-Path $root 'templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1'
$workflowPath = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
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

foreach ($path in @($modulePath, $adapterPath, $workflowPath, $adoptionPath, $protocolPath)) {
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
        $null -eq $cleanStartClassifier) {
        Add-Failure 'TEST-0080/TEST-0127 pure lifecycle module does not export the canonical adoption path, assessment, strategy, inventory, and manifest contract.'
    }
    else {
        $protocolSha = ('a' * 40) -join ''
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
        $emptyInventory = @(& $surfaceClassifier -Paths $null)
        if ($emptyInventory.Count -ne 0 -or
            $moduleRecognizedInventory.Count -ne 1 -or
            [string]$moduleRecognizedInventory[0] -cne $moduleRecognizedPath) {
            Add-Failure 'TEST-0127 module-owned relevant-path predicate and surface inventory disagree.'
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
    }
}

if (Test-Path -LiteralPath $workflowPath -PathType Leaf) {
    $workflow = Get-Content -LiteralPath $workflowPath -Raw
    foreach ($required in @(
        'BOOTSTRAP_PROTOCOL_TAG: v0.11.0',
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
        'Test-MeAndAIConsumerGovernancePath -Path $Path',
        'Test-MeAndAILegacyGovernancePath -Path $path',
        'Test-MeAndAILegacyCommonAuthorityPath -Path $surface',
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
        'function Test-CompletedLegacyCommonAuthorityPath'
    )) {
        if ($adapter.Contains($duplicatedPolicy)) {
            Add-Failure "TEST-0127 bootstrap adapter duplicates module-owned assessment policy '$duplicatedPolicy'."
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

$adapterTestPath = Join-Path $root 'tests/capabilities-bootstrap-adapter.tests.ps1'
if (-not (Test-Path -LiteralPath $adapterTestPath -PathType Leaf)) {
    Add-Failure 'TEST-0028 missing bootstrap adapter integration tests.'
}
elseif ($failures.Count -eq 0) {
    $engine = (Get-Process -Id $PID).Path
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
$scenarioResult = New-MeAndAIScenarioResult `
    -Owner 'tests/capabilities-bootstrap.tests.ps1' `
    -SourcePaths @($PSCommandPath, $adapterTestPath) `
    -AuthorityPath $scenarioAuthorityPath
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
